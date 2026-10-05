"""
test_golden_seed_day.py – Golden walkthrough seed day and coupling tests (D12).

Tests:
1. Golden test: running the allocation engine on the seeded day produces:
   - At least one UNAVOIDABLE deferral (e.g. TOO_LARGE or WINDOW_INFEASIBLE)
   - At least one CHOICE deferral (e.g. TRIP_LIMIT or CAPACITY_FULL)
   - At least one FUEL_QUOTA deferral
   - Fairness: deferred_yesterday=1 outlet is served ahead of an equivalent order
   - Account coupling holds: headline store manager (store@waypoint.test) is bound
     to an outlet on a trip, and headline driver (driver@waypoint.test) is bound to
     the vehicle carrying that trip, at Peliyagoda.
2. Idempotency: re-running seed_all produces identical records without error.
3. DEMO_NOW clock sits at 2025-07-31T14:00:00+05:30 (the day before delivery date 2025-08-01).
"""

from datetime import date
import pytest
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.clock import business_now
from app.models.domain import (
    Order,
    Outlet,
    OutletServiceState,
    Vehicle,
    VehicleAvailability,
    FuelLedger,
    User,
)
from app.engine.types import (
    AllocatorInput,
    OrderInput,
    WeeklyFuelLedger,
)
from app.engine.constants import DeferralClass, DeferralCode
from app.engine.allocator import allocate
from app.seed.loader import seed_all
from app.seed.day_generator import (
    build_engine_reference_from_db,
    generate_seeded_day_structures,
    seed_walkthrough_data,
    SEED_DATE_STR,
    SEED_DATE,
    ISO_YEAR,
    ISO_WEEK,
)


def test_golden_walkthrough_plan_and_coupling(db: Session):
    """
    CI Golden Test (D12):
    Enforces the walkthrough story on the seeded delivery day (2025-08-01).
    Fails if any code change breaks the story.
    """
    # 1. Seed complete database
    res = seed_all(db, force=True)
    assert res["reference"]["outlets"] == 120
    assert res["reference"]["vehicles"] == 60

    # 2. Verify DEMO_NOW is day before delivery day at 14:00
    now = business_now()
    assert now.strftime("%Y-%m-%d %H:%M") == "2025-07-31 14:00"
    assert settings.SEED_DELIVERY_DATE == "2025-08-01"

    # 3. Load engine reference and structures from seeded DB
    ref = build_engine_reference_from_db(db)
    structures = generate_seeded_day_structures(ref)

    # 4. Prepare available vehicles and fuel ledger for Peliyagoda
    avail_vids = [
        v_id for v_id, v in ref.vehicles.items()
        if v.depot == "Peliyagoda" and v_id not in structures["workshop_vids"]
    ]

    # Verify at least one reefer is in workshop
    workshop_vids = structures["workshop_vids"]
    assert "VEH006" in workshop_vids, "VEH006 (reefer) must be in workshop"
    assert ref.vehicles["VEH006"].temp == "reefer"

    inp = AllocatorInput(
        depot="Peliyagoda",
        delivery_date=SEED_DATE_STR,
        iso_year=ISO_YEAR,
        iso_week=ISO_WEEK,
        is_operating=True,
        orders=structures["pel_orders"],
        available_vehicle_ids=avail_vids,
        locked_slots=[],
        fuel_ledger=structures["fuel_ledgers"],
        reference=ref,
    )

    output = allocate(inp)

    # 5. Assert deferral criteria:
    # - At least one UNAVOIDABLE deferral
    # - At least one CHOICE deferral
    # - At least one FUEL_QUOTA deferral
    deferral_classes = {d.reason_class for d in output.deferrals}
    deferral_codes = {d.reason_code for d in output.deferrals}

    assert DeferralClass.UNAVOIDABLE in deferral_classes, (
        f"Expected at least one UNAVOIDABLE deferral, got classes: {deferral_classes}"
    )
    assert DeferralClass.CHOICE in deferral_classes, (
        f"Expected at least one CHOICE deferral, got classes: {deferral_classes}"
    )
    assert DeferralCode.FUEL_QUOTA in deferral_codes, (
        f"Expected at least one FUEL_QUOTA deferral, got codes: {deferral_codes}"
    )

    # 6. Assert fairness rule:
    # OUT004 has deferred_yesterday=True and is served on a trip
    out004_orders = [o for o in structures["pel_orders"] if o.outlet_id == "OUT004"]
    assert len(out004_orders) >= 1
    assert out004_orders[0].deferred_yesterday is True

    served_order_ids = {o.order_id for t in output.trips for o in t.orders}
    assert out004_orders[0].order_id in served_order_ids, (
        "Headline outlet OUT004 (deferred yesterday) must be planned on a trip"
    )

    # 7. Assert account coupling (D12):
    store_mgr = db.query(User).filter(
        (User.id == "store@waypoint.test") | (User.username == "store@waypoint.test")
    ).first()
    driver = db.query(User).filter(
        (User.id == "driver@waypoint.test") | (User.username == "driver@waypoint.test")
    ).first()
    loader = db.query(User).filter(
        (User.id == "loader@waypoint.test") | (User.username == "loader@waypoint.test")
    ).first()

    assert store_mgr is not None
    assert driver is not None
    assert loader is not None

    assert store_mgr.outlet_id == "OUT004"
    coupled_vehicle_id = driver.vehicle_id
    assert coupled_vehicle_id is not None

    # Check that OUT004 is indeed carried by driver's vehicle
    matching_trips = [
        t for t in output.trips
        if t.vehicle_id == coupled_vehicle_id and any(o.outlet_id == "OUT004" for o in t.orders)
    ]
    assert len(matching_trips) >= 1, (
        f"Coupled vehicle {coupled_vehicle_id} must carry OUT004 on a trip at Peliyagoda"
    )
    assert ref.vehicles[coupled_vehicle_id].depot == "Peliyagoda"


def test_seed_idempotency_walkthrough_day(db: Session):
    """Re-running seed_all preserves exact counts without raising constraint errors."""
    # First seed
    res1 = seed_all(db, force=True)
    orders_count_1 = db.query(Order).count()
    service_states_1 = db.query(OutletServiceState).count()
    availabilities_1 = db.query(VehicleAvailability).count()
    fuel_ledgers_1 = db.query(FuelLedger).count()

    # Second seed
    res2 = seed_all(db, force=True)
    orders_count_2 = db.query(Order).count()
    service_states_2 = db.query(OutletServiceState).count()
    availabilities_2 = db.query(VehicleAvailability).count()
    fuel_ledgers_2 = db.query(FuelLedger).count()

    assert orders_count_1 == orders_count_2
    assert service_states_1 == service_states_2
    assert availabilities_1 == availabilities_2
    assert fuel_ledgers_1 == fuel_ledgers_2
    assert orders_count_1 > 0


def test_kandy_seeded_day(db: Session):
    """Verify smaller Kandy delivery day exists on 2025-08-01."""
    seed_all(db, force=True)
    kandy_orders = db.query(Order).filter(Order.id.like("ORD-KAN-%")).all()
    assert len(kandy_orders) >= 40, "Kandy should have at least 40 orders"

    # Verify Kandy workshop vehicle
    kandy_ws = db.query(VehicleAvailability).filter_by(
        vehicle_id="VEH040", date=SEED_DATE, status="in_workshop"
    ).first()
    assert kandy_ws is not None, "VEH040 should be in_workshop on 2025-08-01"
