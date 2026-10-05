"""
test_validator.py – one failing plan per rule H1-H12.

Each test constructs a minimally bad TripPlan that violates exactly the named rule,
then asserts that the validator returns that rule ID in its violations.
All reference values come from the CSV fixtures.
"""

import pytest
from app.engine.types import (
    AllocatorInput,
    DistrictRef,
    OrderInput,
    OutletRef,
    ReferenceData,
    TripPlan,
    VehicleRef,
    WeeklyFuelLedger,
)
from app.engine.validator import validate_trip


def make_order(
    order_id, outlet_id, brand, district, depot,
    kg=100.0, vol=0.5, temp="ambient",
    deferred_yesterday=False, days_since_last_served=0,
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


def make_trip(
    vehicle_id, trip_no, brand, district, depot, orders
):
    return TripPlan(
        trip_key=f"{vehicle_id}_trip{trip_no}",
        vehicle_id=vehicle_id,
        trip_no=trip_no,
        brand=brand,
        district=district,
        depot=depot,
        orders=orders,
    )


def validate(trip, ref_data, vref, status="available", is_operating=True,
             fuel_committed=0.0, fresh_budget=0.0, st_budget=0.0,
             prev_end=0, trip_count=1, reload_buf=0):
    from app.engine.validator import validate_trip
    return validate_trip(
        trip=trip,
        ref=ref_data,
        vehicle_ref=vref,
        vehicle_status=status,
        is_operating=is_operating,
        fuel_already_committed_l=fuel_committed,
        fresh_budget_used=fresh_budget,
        style_tech_budget_used=st_budget,
        prev_trip_end_min=prev_end,
        trip_count_for_vehicle=trip_count,
        reload_buffer_min=reload_buf,
    )


def assert_rule_violated(result, rule_id):
    rule_ids = [v.rule for v in result.violations]
    assert rule_id in rule_ids, f"Expected rule {rule_id} violated but got: {rule_ids}"
    assert not result.is_valid


# ---------------------------------------------------------------------------
# H1: same brand and district
# ---------------------------------------------------------------------------

def test_h1_mixed_brand(ref_data: ReferenceData):
    """H1: order brand doesn't match trip brand."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh"
    )
    vref = ref_data.vehicles["VEH008"]  # ambient truck, Peliyagoda

    # Order brand is Style but trip brand is Fresh
    order = make_order("O1", colombo_fresh.outlet_id, "Style", "Colombo", "Peliyagoda")
    trip = make_trip("VEH008", 1, "Fresh", "Colombo", "Peliyagoda", [order])

    result = validate(trip, ref_data, vref)
    assert_rule_violated(result, "H1")


def test_h1_mixed_district(ref_data: ReferenceData):
    """H1: order district doesn't match trip district."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh"
    )
    vref = ref_data.vehicles["VEH008"]

    # Order district is Gampaha but trip district is Colombo
    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Gampaha", "Peliyagoda")
    trip = make_trip("VEH008", 1, "Fresh", "Colombo", "Peliyagoda", [order])

    result = validate(trip, ref_data, vref)
    assert_rule_violated(result, "H1")


# ---------------------------------------------------------------------------
# H2: chilled needs reefer
# ---------------------------------------------------------------------------

def test_h2_chilled_on_ambient(ref_data: ReferenceData):
    """H2: chilled order placed on an ambient vehicle."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    ambient_vref = next(v for v in ref_data.vehicles.values() if v.temp == "ambient" and v.depot == "Peliyagoda")

    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda", temp="chilled")
    trip = make_trip(ambient_vref.vehicle_id, 1, "Fresh", "Colombo", "Peliyagoda", [order])

    result = validate(trip, ref_data, ambient_vref)
    assert_rule_violated(result, "H2")


# ---------------------------------------------------------------------------
# H3: van_only needs van
# ---------------------------------------------------------------------------

def test_h3_van_only_on_truck(ref_data: ReferenceData):
    """H3: van_only outlet served by a truck."""
    van_only = next(o for o in ref_data.outlets.values() if o.parking_constraint == "van_only")
    truck_vref = next(v for v in ref_data.vehicles.values() if v.type == "truck" and v.depot == van_only.depot)

    order = make_order("O1", van_only.outlet_id, van_only.brand, van_only.district, van_only.depot)
    trip = make_trip(truck_vref.vehicle_id, 1, van_only.brand, van_only.district, van_only.depot, [order])

    result = validate(trip, ref_data, truck_vref)
    assert_rule_violated(result, "H3")


# ---------------------------------------------------------------------------
# H4: vehicle serves own depot
# ---------------------------------------------------------------------------

def test_h4_wrong_depot(ref_data: ReferenceData):
    """H4: Peliyagoda vehicle serving a Kandy outlet."""
    kandy_outlet = next(o for o in ref_data.outlets.values() if o.depot == "Kandy" and o.brand == "Fresh" and o.parking_constraint == "normal")
    peliyagoda_vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.type == "truck" and v.temp == "ambient")

    order = make_order("O1", kandy_outlet.outlet_id, kandy_outlet.brand, kandy_outlet.district, "Kandy")
    # Trip depot matches order depot (Kandy) but vehicle depot is Peliyagoda
    trip = make_trip(peliyagoda_vref.vehicle_id, 1, kandy_outlet.brand, kandy_outlet.district, "Kandy", [order])

    result = validate(trip, ref_data, peliyagoda_vref)
    assert_rule_violated(result, "H4")


# ---------------------------------------------------------------------------
# H5: whole orders (structural; validator always passes H5 since orders are pre-built)
# In practice H5 means the allocator never splits. We test the boundary.
# ---------------------------------------------------------------------------

def test_h5_passes_for_whole_order(ref_data: ReferenceData):
    """H5: a well-formed trip (one order per stop) should not violate H5."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "reefer")
    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda")
    trip = make_trip(vref.vehicle_id, 1, "Fresh", "Colombo", "Peliyagoda", [order])
    result = validate(trip, ref_data, vref)
    # Should not violate H5
    rule_ids = [v.rule for v in result.violations]
    assert "H5" not in rule_ids


# ---------------------------------------------------------------------------
# H6: weight and volume capacity
# ---------------------------------------------------------------------------

def test_h6_overweight(ref_data: ReferenceData):
    """H6: order weight exceeds vehicle capacity."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    # Use smallest Peliyagoda vehicle
    vref = min(
        (v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient"),
        key=lambda v: v.weight_cap_kg
    )
    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda",
                       kg=vref.weight_cap_kg + 1.0, vol=0.5)
    trip = make_trip(vref.vehicle_id, 1, "Fresh", "Colombo", "Peliyagoda", [order])
    result = validate(trip, ref_data, vref)
    assert_rule_violated(result, "H6")


def test_h6_overvolume(ref_data: ReferenceData):
    """H6: order volume exceeds vehicle capacity."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    vref = min(
        (v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient"),
        key=lambda v: v.volume_cap_m3
    )
    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda",
                       kg=100.0, vol=vref.volume_cap_m3 + 1.0)
    trip = make_trip(vref.vehicle_id, 1, "Fresh", "Colombo", "Peliyagoda", [order])
    result = validate(trip, ref_data, vref)
    assert_rule_violated(result, "H6")


# ---------------------------------------------------------------------------
# H7: at most 2 trips per vehicle per day
# ---------------------------------------------------------------------------

def test_h7_third_trip(ref_data: ReferenceData):
    """H7: vehicle assigned 3 trips."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient")
    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda")
    trip = make_trip(vref.vehicle_id, 3, "Fresh", "Colombo", "Peliyagoda", [order])
    result = validate(trip, ref_data, vref, trip_count=3)
    assert_rule_violated(result, "H7")


# ---------------------------------------------------------------------------
# H8: time budget (formula, no waiting)
# ---------------------------------------------------------------------------

def test_h8_fresh_budget_exceeded(ref_data: ReferenceData):
    """H8: Fresh trip pushes cumulative over 270 min."""
    # Use Puttalam (outbound 173 min already). 3 stops = 101 min on top of 173 = well above 270.
    puttalam_outlets = [
        o for o in ref_data.outlets.values()
        if o.district == "Puttalam" and o.brand == "Fresh"
    ]
    assert len(puttalam_outlets) >= 1
    vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient")

    orders = [make_order("O1", puttalam_outlets[0].outlet_id, "Fresh", "Puttalam", "Peliyagoda")]
    trip = make_trip(vref.vehicle_id, 1, "Fresh", "Puttalam", "Peliyagoda", orders)

    from app.engine.formula import compute_trip_minutes
    dist = ref_data.districts["Puttalam"]
    mins = compute_trip_minutes(orders, dist, ref_data, "Fresh")

    # Budget already used: set it so total would exceed 270
    budget_already = 270 - mins + 1  # makes total exceed by 1
    result = validate(trip, ref_data, vref, fresh_budget=budget_already)
    assert_rule_violated(result, "H8")


# ---------------------------------------------------------------------------
# H9: only available vehicles
# ---------------------------------------------------------------------------

def test_h9_in_workshop(ref_data: ReferenceData):
    """H9: vehicle in_workshop."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient")
    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda")
    trip = make_trip(vref.vehicle_id, 1, "Fresh", "Colombo", "Peliyagoda", [order])
    result = validate(trip, ref_data, vref, status="in_workshop")
    assert_rule_violated(result, "H9")


# ---------------------------------------------------------------------------
# H10: operating day
# ---------------------------------------------------------------------------

def test_h10_non_operating_day(ref_data: ReferenceData):
    """H10: planning on a non-operating day."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient")
    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda")
    trip = make_trip(vref.vehicle_id, 1, "Fresh", "Colombo", "Peliyagoda", [order])
    result = validate(trip, ref_data, vref, is_operating=False)
    assert_rule_violated(result, "H10")


# ---------------------------------------------------------------------------
# H11: arrival within window (waiting-aware ETA)
# ---------------------------------------------------------------------------

def test_h11_arrival_after_close(ref_data: ReferenceData):
    """H11: far-district plan that arrives after the window closes."""
    # Badulla (outbound 186 min). Fresh window closes at 08:00 = 480 min.
    # 03:30 depart + 186 min = 06:36 arrival; but close at ~07:30 Fresh. Should pass.
    # Instead, use a window_close_time of e.g. 04:00 (fabricate via a mock outlet).
    # We'll use a real Puttalam outlet which has close=07:30 or 08:00, but pick a 
    # trip where the departure is pushed so late it misses.
    # 
    # Simplest approach: use prev_fresh_end_min to delay trip 2 depart time.
    puttalam_outlets = [
        o for o in ref_data.outlets.values()
        if o.district == "Puttalam" and o.brand == "Fresh"
    ]
    if not puttalam_outlets:
        pytest.skip("No Puttalam Fresh outlets")

    outlet = puttalam_outlets[0]
    vref = next(v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient")
    order = make_order("O1", outlet.outlet_id, "Fresh", "Puttalam", "Peliyagoda")
    trip = make_trip(vref.vehicle_id, 2, "Fresh", "Puttalam", "Peliyagoda", [order])

    # Puttalam outbound = 173 min. Departure at 03:30 (210 min), so arrival = 383 min = 06:23.
    # If we set prev_trip_end_min such that trip2 departs late enough to arrive after window close...
    # Window close for this outlet from CSV
    from app.engine.formula import hhmm_to_minutes
    close_min = hhmm_to_minutes(outlet.window_close_time)
    # We need: depart_min + 173 > close_min
    # depart_min = prev_end + reload_buffer
    # So prev_end > close_min - 173
    late_prev_end = close_min - 173 + 5  # arrives 5 min after window close

    result = validate(trip, ref_data, vref, prev_end=late_prev_end)
    assert_rule_violated(result, "H11")


# ---------------------------------------------------------------------------
# H12: weekly fuel quota
# ---------------------------------------------------------------------------

def test_h12_fuel_exceeded(ref_data: ReferenceData):
    """H12: fuel would exceed weekly quota."""
    colombo_fresh = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.parking_constraint == "normal"
    )
    vref = min(
        (v for v in ref_data.vehicles.values() if v.depot == "Peliyagoda" and v.temp == "ambient"),
        key=lambda v: v.weekly_fuel_quota_l
    )
    order = make_order("O1", colombo_fresh.outlet_id, "Fresh", "Colombo", "Peliyagoda")
    trip = make_trip(vref.vehicle_id, 1, "Fresh", "Colombo", "Peliyagoda", [order])

    from app.engine.formula import compute_trip_fuel
    dist = ref_data.districts["Colombo"]
    fuel_for_this = compute_trip_fuel(1, dist, vref.km_per_l)
    # Set committed so total exceeds quota
    fuel_already = vref.weekly_fuel_quota_l - fuel_for_this + 0.1
    result = validate(trip, ref_data, vref, fuel_committed=fuel_already)
    assert_rule_violated(result, "H12")
