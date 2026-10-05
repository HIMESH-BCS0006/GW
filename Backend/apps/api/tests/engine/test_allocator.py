"""
test_allocator.py – allocator tests covering:
  - Determinism (two runs produce identical output)
  - Two-clocks rule (passes H8 formula, fails H11 waiting-aware ETA)
  - Chilled never on ambient
  - van_only only on vans
  - Workshop vehicles never used
  - Ambient orders prefer ambient trucks (keep reefers free)
  - Deferral diagnosis: code, explanation with numbers, consequence, class (UNAVOIDABLE vs CHOICE)
  - Locked trips preserved as fixed input on re-run
  - Performance: 300 orders in under 2 seconds
"""

import time
import pytest
from app.engine.allocator import allocate
from app.engine.constants import DeferralClass, DeferralCode
from app.engine.types import (
    AllocatorInput,
    OrderInput,
    ReferenceData,
    VehicleSlot,
    WeeklyFuelLedger,
)
from app.engine.validator import validate_trip


def make_test_order(
    order_id: str,
    outlet_id: str,
    brand: str,
    district: str,
    depot: str,
    kg: float = 100.0,
    vol: float = 0.5,
    temp: str = "ambient",
    deferred_yesterday: bool = False,
    days_since_last_served: int = 0,
):
    return OrderInput(
        order_id=order_id,
        outlet_id=outlet_id,
        brand=brand,
        district=district,
        depot=depot,
        temp_requirement=temp,
        order_weight_kg=kg,
        order_volume_m3=vol,
        deferred_yesterday=deferred_yesterday,
        days_since_last_served=days_since_last_served,
    )


def test_determinism_two_runs_identical(ref_data: ReferenceData):
    """Running the allocator twice on the exact same inputs produces identical output."""
    # Create a batch of orders across Peliyagoda districts
    orders = []
    peliyagoda_outlets = [o for o in ref_data.outlets.values() if o.depot == "Peliyagoda"]
    for i, out in enumerate(peliyagoda_outlets[:30]):
        temp = "chilled" if (out.brand == "Fresh" and i % 3 == 0) else "ambient"
        orders.append(make_test_order(
            f"ORD-{i:03d}", out.outlet_id, out.brand, out.district, "Peliyagoda",
            kg=150.0 + i * 5, vol=0.8, temp=temp
        ))

    available_vids = [v.vehicle_id for v in ref_data.vehicles.values() if v.depot == "Peliyagoda"]

    inp1 = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=list(orders),
        available_vehicle_ids=list(available_vids),
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )
    inp2 = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=list(orders),
        available_vehicle_ids=list(available_vids),
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )

    out1 = allocate(inp1)
    out2 = allocate(inp2)

    assert len(out1.trips) == len(out2.trips), "Trip counts must match"
    assert len(out1.deferrals) == len(out2.deferrals), "Deferral counts must match"

    for t1, t2 in zip(out1.trips, out2.trips):
        assert t1.trip_key == t2.trip_key
        assert t1.vehicle_id == t2.vehicle_id
        assert t1.trip_no == t2.trip_no
        assert t1.brand == t2.brand
        assert t1.district == t2.district
        assert [o.order_id for o in t1.orders] == [o.order_id for o in t2.orders]
        assert [s.eta_clock for s in t1.stops] == [s.eta_clock for s in t2.stops]

    for d1, d2 in zip(out1.deferrals, out2.deferrals):
        assert d1.order_id == d2.order_id
        assert d1.reason_code == d2.reason_code
        assert d1.reason_class == d2.reason_class


def test_chilled_never_on_ambient(ref_data: ReferenceData):
    """Validator and allocator ensure chilled orders are NEVER placed on ambient vehicles."""
    colombo_fresh = [
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    ]
    # Provide only 1 ambient truck and 1 reefer truck
    reefer_v = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "reefer" and v.type == "truck")
    ambient_v = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient" and v.type == "truck")

    orders = [
        make_test_order("O-CHL", colombo_fresh[0].outlet_id, "Fresh", "Colombo", "Peliyagoda", temp="chilled"),
        make_test_order("O-AMB", colombo_fresh[1].outlet_id, "Fresh", "Colombo", "Peliyagoda", temp="ambient"),
    ]

    inp = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=orders,
        available_vehicle_ids=[ambient_v.vehicle_id, reefer_v.vehicle_id],
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )
    result = allocate(inp)

    # Check every trip containing O-CHL has vehicle.temp == reefer
    for trip in result.trips:
        for o in trip.orders:
            if o.temp_requirement == "chilled":
                vref = ref_data.vehicles[trip.vehicle_id]
                assert vref.temp == "reefer", f"Chilled order assigned to ambient vehicle {vref.vehicle_id}"


def test_van_only_only_on_vans(ref_data: ReferenceData):
    """van_only outlets are never served by a truck."""
    van_outlets = [o for o in ref_data.outlets.values() if o.parking_constraint == "van_only"]
    assert len(van_outlets) > 0

    vo = van_outlets[0]
    order = make_test_order("ORD-VO", vo.outlet_id, vo.brand, vo.district, vo.depot)

    all_vids = [v.vehicle_id for v in ref_data.vehicles.values() if v.depot == vo.depot]

    inp = AllocatorInput(
        depot=vo.depot,
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=[order],
        available_vehicle_ids=all_vids,
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )
    result = allocate(inp)

    # If served, must be on a van
    for trip in result.trips:
        if any(o.order_id == "ORD-VO" for o in trip.orders):
            vref = ref_data.vehicles[trip.vehicle_id]
            assert vref.type == "van", f"van_only order placed on {vref.type} {vref.vehicle_id}"


def test_workshop_vehicles_never_used(ref_data: ReferenceData):
    """Vehicles not in available_vehicle_ids are in_workshop and never used."""
    peliyagoda_vrefs = [v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda"]
    workshop_v = peliyagoda_vrefs[0]
    available_vids = [v.vehicle_id for v in peliyagoda_vrefs[1:]]

    colombo_fresh = next(o for o in ref_data.outlets.values() if o.district == "Colombo" and o.brand == "Fresh")
    order = make_test_order("ORD-1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda")

    inp = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=[order],
        available_vehicle_ids=available_vids,  # workshop_v excluded
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )
    result = allocate(inp)

    assigned_vids = [t.vehicle_id for t in result.trips]
    assert workshop_v.vehicle_id not in assigned_vids, "in_workshop vehicle must never be assigned"


def test_ambient_orders_prefer_ambient_trucks(ref_data: ReferenceData):
    """When both ambient and reefer trucks are available, ambient orders choose ambient trucks to keep reefers free."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    # Pick 1 reefer truck and 1 ambient truck with same or comparable capacity
    reefer_truck = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "reefer" and v.type == "truck")
    ambient_truck = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient" and v.type == "truck")

    order = make_test_order("O-AMB", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda", temp="ambient")

    inp = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=[order],
        available_vehicle_ids=[reefer_truck.vehicle_id, ambient_truck.vehicle_id],
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )
    result = allocate(inp)

    assert len(result.trips) == 1
    chosen_vid = result.trips[0].vehicle_id
    assert ref_data.vehicles[chosen_vid].temp == "ambient", "Ambient order should select ambient vehicle to keep reefer free"


def test_two_clocks_rule_h8_pass_h11_fail(ref_data: ReferenceData):
    """
    Two clocks rule (A4):
    A plan that passes H8 formula (time <= 270 min) but fails H11 (waiting pushes arrival after window close)
    is rejected.
    """
    colombo_fresh = [
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.dock_type == "street"
    ]
    vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient")

    # OUT001 window: 05:00 - 07:30
    # Create trip on trip_no 2 where prev_trip ended at 07:15.
    # Outbound travel is 24 min. 07:15 + 24 min = 07:39 arrival > 07:30 window close!
    # Formula trip_minutes for 1 stop = 24 + 16 = 40 min <= 270 min (passes H8!).
    # But ETA arrival is 07:39 > 07:30 (fails H11!).
    out_730 = next(o for o in colombo_fresh if o.window_close_time == "07:30")
    order = make_test_order("O-LATE", out_730.outlet_id, "Fresh", "Colombo", "Peliyagoda")

    from app.engine.formula import hhmm_to_minutes
    prev_end_min = hhmm_to_minutes("07:15")

    from app.engine.types import TripPlan
    from app.engine.formula import compute_trip_minutes
    trip = TripPlan(
        trip_key=f"{vref.vehicle_id}_trip2",
        vehicle_id=vref.vehicle_id,
        trip_no=2,
        brand="Fresh",
        district="Colombo",
        depot="Peliyagoda",
        orders=[order],
    )

    # Validate with fresh_budget_used = 40 min (cumulative = 80 min <= 270 min, H8 passes!)
    res = validate_trip(
        trip=trip,
        ref=ref_data,
        vehicle_ref=vref,
        vehicle_status="available",
        is_operating=True,
        fuel_already_committed_l=0.0,
        fresh_budget_used=40.0,
        style_tech_budget_used=0.0,
        prev_trip_end_min=prev_end_min,
        trip_count_for_vehicle=2,
    )

    rule_ids = [v.rule for v in res.violations]
    assert "H8" not in rule_ids, "H8 formula should pass because 80 min <= 270 min"
    assert "H11" in rule_ids, "H11 must fail because arrival 07:39 > window close 07:30"
    assert not res.is_valid, "Plan failing H11 must be invalid despite passing H8"


def test_deferral_diagnosis_unavoidable_vs_choice(ref_data: ReferenceData):
    """
    Deferral class is computed by the solo-feasibility test:
    - Order impossible even alone on any vehicle -> UNAVOIDABLE
    - Order feasible alone, but deferred due to fleet exhaustion -> CHOICE
    """
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )

    # Case 1: Chilled order when NO reefer vehicles exist in the depot fleet
    ambient_vids = [
        v.vehicle_id for v in ref_data.vehicles.values()
        if v.depot == "Peliyagoda" and v.temp == "ambient"
    ]
    order_chl = make_test_order("O-UNAVOID", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda", temp="chilled")

    inp_unavoid = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=[order_chl],
        available_vehicle_ids=ambient_vids,  # no reefers!
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )
    res_unavoid = allocate(inp_unavoid)
    assert len(res_unavoid.deferrals) == 1
    d_unavoid = res_unavoid.deferrals[0]
    assert d_unavoid.reason_code == DeferralCode.NO_REEFER
    assert d_unavoid.reason_class == DeferralClass.UNAVOIDABLE
    assert "chilled" in d_unavoid.reason_text.lower()

    # Case 2: Feasible order alone, but only 1 vehicle exists and its 2 trips are already filled
    vref = ambient_vids[0]
    cap = ref_data.vehicles[vref].weight_cap_kg
    o_first = make_test_order("O-FIRST", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda", kg=cap)
    o_second = make_test_order("O-SECOND", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda", kg=cap)
    o_third = make_test_order("O-THIRD", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda", kg=100.0)

    inp_choice = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=[o_first, o_second, o_third],
        available_vehicle_ids=[vref],
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )
    res_choice = allocate(inp_choice)
    # o_third cannot fit on the single vehicle (both trip 1 and trip 2 are full) and will be deferred
    d_choice = next(d for d in res_choice.deferrals if d.order_id == "O-THIRD")
    assert d_choice.reason_class == DeferralClass.CHOICE, "Feasible alone, so class must be CHOICE"


def test_locked_trips_preserved_on_rerun(ref_data: ReferenceData):
    """Locked trips (CONFIRMED or later) passed in locked_slots are preserved and count against vehicle limits."""
    colombo_fresh = [
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    ]
    vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient")

    order_locked = make_test_order("ORD-LOCKED", colombo_fresh[0].outlet_id, "Fresh", "Colombo", "Peliyagoda")
    order_new = make_test_order("ORD-NEW", colombo_fresh[1].outlet_id, "Fresh", "Colombo", "Peliyagoda")

    locked_slot = VehicleSlot(
        vehicle_id=vref.vehicle_id,
        trip_no=1,
        vehicle_ref=vref,
        used_weight_kg=order_locked.order_weight_kg,
        used_volume_m3=order_locked.order_volume_m3,
        current_trip_minutes=60.0,
        current_fuel_l=10.0,
        orders=[order_locked],
        brand="Fresh",
        district="Colombo",
        is_locked=True,
    )

    inp = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=[order_new],
        available_vehicle_ids=[vref.vehicle_id],
        locked_slots=[locked_slot],
        fuel_ledger=[],
        reference=ref_data,
    )
    result = allocate(inp)

    # Locked trip should be present in output trips
    trip_keys = [t.trip_key for t in result.trips]
    assert f"{vref.vehicle_id}_trip1" in trip_keys
    locked_trip = next(t for t in result.trips if t.trip_key == f"{vref.vehicle_id}_trip1")
    assert any(o.order_id == "ORD-LOCKED" for o in locked_trip.orders)


def test_performance_300_orders_under_2_seconds(ref_data: ReferenceData):
    """Allocating 300 orders takes under 2 seconds."""
    peliyagoda_outlets = [o for o in ref_data.outlets.values() if o.depot == "Peliyagoda"]
    available_vids = [v.vehicle_id for v in ref_data.vehicles.values() if v.depot == "Peliyagoda"]

    orders = []
    for i in range(300):
        out = peliyagoda_outlets[i % len(peliyagoda_outlets)]
        temp = "chilled" if (out.brand == "Fresh" and i % 4 == 0) else "ambient"
        orders.append(make_test_order(
            f"ORD-PERF-{i:03d}",
            out.outlet_id,
            out.brand,
            out.district,
            "Peliyagoda",
            kg=50.0 + (i % 20) * 10,
            vol=0.3 + (i % 10) * 0.1,
            temp=temp,
            days_since_last_served=i % 7,
        ))

    inp = AllocatorInput(
        depot="Peliyagoda",
        delivery_date="2025-08-01",
        iso_year=2025,
        iso_week=31,
        is_operating=True,
        orders=orders,
        available_vehicle_ids=available_vids,
        locked_slots=[],
        fuel_ledger=[],
        reference=ref_data,
    )

    t0 = time.perf_counter()
    result = allocate(inp)
    elapsed = time.perf_counter() - t0

    assert elapsed < 2.0, f"300 orders allocation took {elapsed:.3f}s (budget: 2.0s)"
    assert len(result.trips) > 0
    # Every order must be accounted for: either in a trip or in deferrals
    planned_orders = sum(len(t.orders) for t in result.trips)
    deferred_orders = len(result.deferrals)
    assert planned_orders + deferred_orders == 300
