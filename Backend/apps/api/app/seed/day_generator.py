"""
day_generator.py – deterministic walkthrough delivery day generator and account coupling (D12).

Conforms to Spec 06, Spec 02, and PROJECT_CONTEXT.md sections 10, 11, 14.1.
Generates:
1. Walkthrough delivery day for Peliyagoda (Friday 2025-08-01):
   - Fresh dry orders for all 49 Peliyagoda Fresh outlets.
   - Fresh chilled orders for 25 Peliyagoda Fresh outlets (exceeds reefer capacity).
   - Style orders for 12 Style outlets.
   - Tech orders for 6 Tech outlets.
   - One oversized order (TOO_LARGE / UNAVOIDABLE).
   - Distant district chilled orders triggering FUEL_QUOTA deferrals.
2. Smaller Kandy day on the same date:
   - Fresh dry orders for all 31 Kandy Fresh outlets.
   - Fresh chilled orders for 10 Kandy Fresh outlets.
   - Style orders for 4 Style outlets.
   - Tech orders for 2 Tech outlets.
3. History: outlet_service_state with several outlets deferred_yesterday=1 and varied days_since_last_served.
4. vehicle_availability: in_workshop for VEH006 (reefer), VEH015 (ambient) at Peliyagoda, VEH040 (reefer) at Kandy.
5. fuel_ledger: pre-used weekly litres committed near quota on long-haul vehicles.
6. Account coupling (D12): runs engine in memory, binds headline store manager (OUT004) and headline driver to the vehicle carrying that trip.
"""

from datetime import datetime, date
import random
from typing import Dict, List, Tuple
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.domain import (
    Depot,
    District,
    Outlet,
    Vehicle,
    ServiceAllowance,
    Order,
    OutletServiceState,
    VehicleAvailability,
    FuelLedger,
    User,
)
from app.engine.types import (
    AllocatorInput,
    DistrictRef,
    OrderInput,
    OutletRef,
    ReferenceData,
    VehicleRef,
    WeeklyFuelLedger,
)
from app.engine.allocator import allocate

SEED_DATE_STR = settings.SEED_DELIVERY_DATE
SEED_DATE = datetime.strptime(SEED_DATE_STR, "%Y-%m-%d").date()
ISO_YEAR = 2025
ISO_WEEK = 31  # 2025-08-01 is W31


def build_engine_reference_from_db(db: Session) -> ReferenceData:
    """Build ReferenceData dataclass from database reference tables."""
    districts = {
        d.id: DistrictRef(
            district=d.id,
            depot=d.depot_id,
            depot_to_district_km=d.depot_to_district_km,
            depot_to_district_freeflow_min=d.depot_to_district_freeflow_min,
            inter_stop_km=d.inter_stop_km,
            inter_stop_freeflow_min=d.inter_stop_freeflow_min,
        )
        for d in db.query(District).all()
    }

    outlets = {
        o.id: OutletRef(
            outlet_id=o.id,
            brand=o.brand,
            district=o.district,
            depot=o.depot_id,
            dock_type=o.dock_type,
            parking_constraint=o.parking_constraint,
            window_open_time=o.window_open_time,
            window_close_time=o.window_close_time,
        )
        for o in db.query(Outlet).all()
    }

    vehicles = {
        v.id: VehicleRef(
            vehicle_id=v.id,
            type=v.type,
            temp=v.temp,
            weight_cap_kg=v.weight_cap_kg,
            volume_cap_m3=v.volume_cap_m3,
            km_per_l=v.km_per_l,
            weekly_fuel_quota_l=v.weekly_fuel_quota_l,
            depot=v.depot_id,
        )
        for v in db.query(Vehicle).all()
    }

    service_allowance = {
        (sa.brand, sa.dock_type): sa.service_allowance_min
        for sa in db.query(ServiceAllowance).all()
    }

    return ReferenceData(
        districts=districts,
        outlets=outlets,
        vehicles=vehicles,
        service_allowance=service_allowance,
    )


def generate_seeded_day_structures(ref: ReferenceData) -> dict:
    """
    Deterministically generates the orders, vehicle availability, fuel ledger,
    and outlet service states for 2025-08-01.
    """
    rng = random.Random(1337)  # fixed seed for 100% determinism

    # 1. Outlet Service States (History)
    service_states: List[dict] = []
    # Key outlets with history
    deferred_yesterday_outlets = {"OUT004", "OUT010", "OUT025", "OUT080"}
    alert_outlets = {"OUT010"}  # consecutive_deferrals = 2

    for o_id, out in ref.outlets.items():
        if o_id in alert_outlets:
            consecutive = 2
            last_deferred = date(2025, 7, 31)
            last_served = date(2025, 7, 28)
        elif o_id in deferred_yesterday_outlets:
            consecutive = 1
            last_deferred = date(2025, 7, 31)
            last_served = date(2025, 7, 29)
        else:
            consecutive = 0
            last_deferred = None
            # spread days since last served 1 to 5
            days_ago = (hash(o_id) % 5) + 1
            last_served = date(2025, 7, 31 - min(days_ago, 30))

        service_states.append({
            "outlet_id": o_id,
            "last_served_date": last_served,
            "last_deferred_date": last_deferred,
            "consecutive_deferrals": consecutive,
            "deferred_yesterday": o_id in deferred_yesterday_outlets,
            "days_since_last_served": 4 if o_id in deferred_yesterday_outlets else ((hash(o_id) % 4) + 1),
        })

    service_state_map = {s["outlet_id"]: s for s in service_states}

    # 2. Vehicle Availability (Workshop vehicles)
    # Peliyagoda: VEH006 (reefer truck) and VEH015 (ambient truck)
    # Kandy: VEH040 (reefer truck)
    workshop_vids = {"VEH006", "VEH015", "VEH040"}
    availabilities: List[dict] = []
    for v_id in ref.vehicles:
        is_ws = v_id in workshop_vids
        availabilities.append({
            "vehicle_id": v_id,
            "date": SEED_DATE,
            "status": "in_workshop" if is_ws else "available",
            "note": "Scheduled maintenance" if is_ws else "Available for dispatch",
        })

    # 3. Fuel Ledger (Pre-used weekly litres on long-haul/reefer vehicles)
    fuel_ledgers: List[WeeklyFuelLedger] = [
        WeeklyFuelLedger(vehicle_id="VEH001", iso_year=ISO_YEAR, iso_week=ISO_WEEK, litres_committed=310.0),  # quota 340
        WeeklyFuelLedger(vehicle_id="VEH002", iso_year=ISO_YEAR, iso_week=ISO_WEEK, litres_committed=580.0),  # quota 610
        WeeklyFuelLedger(vehicle_id="VEH003", iso_year=ISO_YEAR, iso_week=ISO_WEEK, litres_committed=450.0),  # quota 480
        WeeklyFuelLedger(vehicle_id="VEH004", iso_year=ISO_YEAR, iso_week=ISO_WEEK, litres_committed=400.0),  # quota 430
        WeeklyFuelLedger(vehicle_id="VEH005", iso_year=ISO_YEAR, iso_week=ISO_WEEK, litres_committed=460.0),  # quota 490
        WeeklyFuelLedger(vehicle_id="VEH007", iso_year=ISO_YEAR, iso_week=ISO_WEEK, litres_committed=560.0),  # quota 590
        WeeklyFuelLedger(vehicle_id="VEH034", iso_year=ISO_YEAR, iso_week=ISO_WEEK, litres_committed=385.0),  # quota 400
        WeeklyFuelLedger(vehicle_id="VEH039", iso_year=ISO_YEAR, iso_week=ISO_WEEK, litres_committed=320.0),  # Kandy reefer
    ]

    # 4. Orders Generation
    placed_time = datetime(2025, 7, 31, 13, 30, 0)
    pel_orders: List[OrderInput] = []
    kandy_orders: List[OrderInput] = []

    # --- Peliyagoda Orders ---
    # 4a. Fresh Dry orders for all 49 Peliyagoda Fresh outlets
    pel_fresh_outlets = [o for o in ref.outlets.values() if o.depot == "Peliyagoda" and o.brand == "Fresh"]
    for out in pel_fresh_outlets:
        st = service_state_map.get(out.outlet_id, {})
        pel_orders.append(OrderInput(
            order_id=f"ORD-PEL-{out.outlet_id}-DRY",
            outlet_id=out.outlet_id,
            brand="Fresh",
            district=out.district,
            depot="Peliyagoda",
            temp_requirement="ambient",
            order_weight_kg=float(rng.randint(300, 900)),
            order_volume_m3=float(round(rng.uniform(1.5, 4.5), 2)),
            deferred_yesterday=st.get("deferred_yesterday", False),
            days_since_last_served=st.get("days_since_last_served", 1),
        ))

    # 4b. Fresh Chilled orders for 25 Peliyagoda Fresh outlets (exceeds reefer capacity)
    for out in pel_fresh_outlets[:25]:
        st = service_state_map.get(out.outlet_id, {})
        pel_orders.append(OrderInput(
            order_id=f"ORD-PEL-{out.outlet_id}-CHL",
            outlet_id=out.outlet_id,
            brand="Fresh",
            district=out.district,
            depot="Peliyagoda",
            temp_requirement="chilled",
            order_weight_kg=float(rng.randint(500, 1500)),
            order_volume_m3=float(round(rng.uniform(2.5, 7.0), 2)),
            deferred_yesterday=False,
            days_since_last_served=st.get("days_since_last_served", 1),
        ))

    # 4c. Matara Chilled orders (distant district, triggers FUEL_QUOTA deferrals)
    matara_fresh = [o for o in ref.outlets.values() if o.district == "Matara" and o.brand == "Fresh"]
    for mf in matara_fresh:
        pel_orders.append(OrderInput(
            order_id=f"ORD-PEL-{mf.outlet_id}-CHL-LONG",
            outlet_id=mf.outlet_id,
            brand="Fresh",
            district="Matara",
            depot="Peliyagoda",
            temp_requirement="chilled",
            order_weight_kg=1200.0,
            order_volume_m3=6.0,
            deferred_yesterday=False,
            days_since_last_served=1,
        ))

    # 4d. Style orders (12 Peliyagoda Style outlets)
    pel_style_outlets = [o for o in ref.outlets.values() if o.depot == "Peliyagoda" and o.brand == "Style"]
    for out in pel_style_outlets[:12]:
        st = service_state_map.get(out.outlet_id, {})
        pel_orders.append(OrderInput(
            order_id=f"ORD-PEL-{out.outlet_id}-STY",
            outlet_id=out.outlet_id,
            brand="Style",
            district=out.district,
            depot="Peliyagoda",
            temp_requirement="ambient",
            order_weight_kg=float(rng.randint(200, 600)),
            order_volume_m3=float(round(rng.uniform(3.0, 8.0), 2)),
            deferred_yesterday=st.get("deferred_yesterday", False),
            days_since_last_served=st.get("days_since_last_served", 2),
        ))

    # 4e. Tech orders (6 Peliyagoda Tech outlets)
    pel_tech_outlets = [o for o in ref.outlets.values() if o.depot == "Peliyagoda" and o.brand == "Tech"]
    for out in pel_tech_outlets[:6]:
        st = service_state_map.get(out.outlet_id, {})
        pel_orders.append(OrderInput(
            order_id=f"ORD-PEL-{out.outlet_id}-TCH",
            outlet_id=out.outlet_id,
            brand="Tech",
            district=out.district,
            depot="Peliyagoda",
            temp_requirement="ambient",
            order_weight_kg=float(rng.randint(400, 1200)),
            order_volume_m3=float(round(rng.uniform(1.5, 4.0), 2)),
            deferred_yesterday=st.get("deferred_yesterday", False),
            days_since_last_served=st.get("days_since_last_served", 3),
        ))

    # 4f. Oversized order -> TOO_LARGE (UNAVOIDABLE deferral)
    pel_orders.append(OrderInput(
        order_id="ORD-PEL-OVERSIZED",
        outlet_id="OUT005",
        brand="Fresh",
        district="Colombo",
        depot="Peliyagoda",
        temp_requirement="ambient",
        order_weight_kg=8500.0,
        order_volume_m3=45.0,
        deferred_yesterday=False,
        days_since_last_served=1,
    ))

    # --- Kandy Orders (smaller day) ---
    kandy_fresh_outlets = [o for o in ref.outlets.values() if o.depot == "Kandy" and o.brand == "Fresh"]
    for out in kandy_fresh_outlets:
        st = service_state_map.get(out.outlet_id, {})
        kandy_orders.append(OrderInput(
            order_id=f"ORD-KAN-{out.outlet_id}-DRY",
            outlet_id=out.outlet_id,
            brand="Fresh",
            district=out.district,
            depot="Kandy",
            temp_requirement="ambient",
            order_weight_kg=float(rng.randint(250, 750)),
            order_volume_m3=float(round(rng.uniform(1.2, 3.8), 2)),
            deferred_yesterday=st.get("deferred_yesterday", False),
            days_since_last_served=st.get("days_since_last_served", 1),
        ))

    for out in kandy_fresh_outlets[:10]:
        st = service_state_map.get(out.outlet_id, {})
        kandy_orders.append(OrderInput(
            order_id=f"ORD-KAN-{out.outlet_id}-CHL",
            outlet_id=out.outlet_id,
            brand="Fresh",
            district=out.district,
            depot="Kandy",
            temp_requirement="chilled",
            order_weight_kg=float(rng.randint(400, 1100)),
            order_volume_m3=float(round(rng.uniform(2.0, 5.5), 2)),
            deferred_yesterday=False,
            days_since_last_served=st.get("days_since_last_served", 1),
        ))

    kandy_style_outlets = [o for o in ref.outlets.values() if o.depot == "Kandy" and o.brand == "Style"]
    for out in kandy_style_outlets[:4]:
        st = service_state_map.get(out.outlet_id, {})
        kandy_orders.append(OrderInput(
            order_id=f"ORD-KAN-{out.outlet_id}-STY",
            outlet_id=out.outlet_id,
            brand="Style",
            district=out.district,
            depot="Kandy",
            temp_requirement="ambient",
            order_weight_kg=float(rng.randint(200, 500)),
            order_volume_m3=float(round(rng.uniform(2.5, 6.0), 2)),
            deferred_yesterday=st.get("deferred_yesterday", False),
            days_since_last_served=st.get("days_since_last_served", 2),
        ))

    kandy_tech_outlets = [o for o in ref.outlets.values() if o.depot == "Kandy" and o.brand == "Tech"]
    for out in kandy_tech_outlets[:2]:
        st = service_state_map.get(out.outlet_id, {})
        kandy_orders.append(OrderInput(
            order_id=f"ORD-KAN-{out.outlet_id}-TCH",
            outlet_id=out.outlet_id,
            brand="Tech",
            district=out.district,
            depot="Kandy",
            temp_requirement="ambient",
            order_weight_kg=float(rng.randint(350, 900)),
            order_volume_m3=float(round(rng.uniform(1.2, 3.2), 2)),
            deferred_yesterday=st.get("deferred_yesterday", False),
            days_since_last_served=st.get("days_since_last_served", 2),
        ))

    return {
        "service_states": service_states,
        "availabilities": availabilities,
        "fuel_ledgers": fuel_ledgers,
        "pel_orders": pel_orders,
        "kandy_orders": kandy_orders,
        "workshop_vids": workshop_vids,
        "placed_time": placed_time,
    }


def seed_walkthrough_data(db: Session, force: bool = False) -> dict:
    """
    Idempotently seeds delivery day records (orders, service states, availability, fuel ledger)
    and executes D12 account coupling.
    """
    ref = build_engine_reference_from_db(db)
    structures = generate_seeded_day_structures(ref)

    # 1. Seed Outlet Service States
    for st in structures["service_states"]:
        existing = db.query(OutletServiceState).filter_by(outlet_id=st["outlet_id"]).first()
        if existing:
            if force:
                existing.last_served_date = st["last_served_date"]
                existing.last_deferred_date = st["last_deferred_date"]
                existing.consecutive_deferrals = st["consecutive_deferrals"]
        else:
            db.add(OutletServiceState(
                outlet_id=st["outlet_id"],
                last_served_date=st["last_served_date"],
                last_deferred_date=st["last_deferred_date"],
                consecutive_deferrals=st["consecutive_deferrals"],
            ))
    db.commit()

    # 2. Seed Vehicle Availability
    for av in structures["availabilities"]:
        existing = db.query(VehicleAvailability).filter_by(
            vehicle_id=av["vehicle_id"], date=av["date"]
        ).first()
        if existing:
            if force:
                existing.status = av["status"]
                existing.note = av["note"]
        else:
            db.add(VehicleAvailability(
                vehicle_id=av["vehicle_id"],
                date=av["date"],
                status=av["status"],
                note=av["note"],
            ))
    db.commit()

    # 3. Seed Fuel Ledger
    for fl in structures["fuel_ledgers"]:
        existing = db.query(FuelLedger).filter_by(
            vehicle_id=fl.vehicle_id, iso_year=fl.iso_year, iso_week=fl.iso_week
        ).first()
        if existing:
            if force:
                existing.litres_committed = fl.litres_committed
        else:
            db.add(FuelLedger(
                vehicle_id=fl.vehicle_id,
                iso_year=fl.iso_year,
                iso_week=fl.iso_week,
                litres_committed=fl.litres_committed,
            ))
    db.commit()

    # 4. Seed Orders (Peliyagoda + Kandy)
    all_order_inputs = structures["pel_orders"] + structures["kandy_orders"]
    placed_at = structures["placed_time"]

    for ord_in in all_order_inputs:
        existing = db.query(Order).filter_by(id=ord_in.order_id).first()
        if existing:
            if force:
                existing.outlet_id = ord_in.outlet_id
                existing.delivery_date = SEED_DATE
                existing.requested_delivery_date = SEED_DATE
                existing.placed_at = placed_at
                existing.status = "SUBMITTED"
                existing.temp_requirement = ord_in.temp_requirement
                existing.order_units = int(ord_in.order_weight_kg / 2.5)
                existing.order_weight_kg = ord_in.order_weight_kg
                existing.order_volume_m3 = ord_in.order_volume_m3
                existing.rolled_over = False
                existing.deferral_count = 1 if ord_in.deferred_yesterday else 0
        else:
            db.add(Order(
                id=ord_in.order_id,
                outlet_id=ord_in.outlet_id,
                delivery_date=SEED_DATE,
                requested_delivery_date=SEED_DATE,
                placed_at=placed_at,
                status="SUBMITTED",
                temp_requirement=ord_in.temp_requirement,
                order_units=int(ord_in.order_weight_kg / 2.5),
                order_weight_kg=ord_in.order_weight_kg,
                order_volume_m3=ord_in.order_volume_m3,
                rolled_over=False,
                deferral_count=1 if ord_in.deferred_yesterday else 0,
            ))
    db.commit()

    # 5. Account Coupling (D12): run engine in memory for Peliyagoda
    avail_vids = [
        v_id for v_id, v in ref.vehicles.items()
        if v.depot == "Peliyagoda" and v_id not in structures["workshop_vids"]
    ]

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

    engine_output = allocate(inp)

    # Find the trip serving OUT004
    coupled_vehicle_id = None
    coupled_outlet_id = "OUT004"
    for trip in engine_output.trips:
        for order in trip.orders:
            if order.outlet_id == coupled_outlet_id:
                coupled_vehicle_id = trip.vehicle_id
                break
        if coupled_vehicle_id:
            break

    # If OUT004 was somehow not on a trip, pick the first trip's first order
    if not coupled_vehicle_id and engine_output.trips:
        first_trip = engine_output.trips[0]
        coupled_vehicle_id = first_trip.vehicle_id
        coupled_outlet_id = first_trip.orders[0].outlet_id

    # Persist the coupling on headline accounts
    store_user = db.query(User).filter(
        (User.id == "store@waypoint.test") | (User.username == "store@waypoint.test")
    ).first()
    if store_user:
        store_user.outlet_id = coupled_outlet_id
        store_user.display_name = f"Headline Store Manager ({coupled_outlet_id})"

    driver_user = db.query(User).filter(
        (User.id == "driver@waypoint.test") | (User.username == "driver@waypoint.test")
    ).first()
    if driver_user and coupled_vehicle_id:
        driver_user.vehicle_id = coupled_vehicle_id
        driver_user.display_name = f"Headline Driver ({coupled_vehicle_id})"

    db.commit()

    return {
        "delivery_date": SEED_DATE_STR,
        "orders_count": db.query(Order).count(),
        "service_states_count": db.query(OutletServiceState).count(),
        "coupled_store_outlet": coupled_outlet_id,
        "coupled_driver_vehicle": coupled_vehicle_id,
        "pel_engine_trips": len(engine_output.trips),
        "pel_engine_deferrals": len(engine_output.deferrals),
    }
