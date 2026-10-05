"""
Planning Service – orchestrates plan generation, validation, trip edits, confirmations,
close-run, summaries, dashboard aggregates, and fallback pre-planned day.
"""

from datetime import date, datetime, time, timedelta
import uuid
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy.orm import Session

from app.core.clock import business_now
from app.core.config import settings
from app.core.errors import (
    AppException,
    ValidationException,
    ConstraintViolationException,
    InvalidTransitionException,
    NotOperatingDayException,
)
from app.models.domain import (
    CalendarDay,
    Deferral,
    FuelLedger,
    Order,
    Outlet,
    OutletServiceState,
    PlanRun,
    ServiceAllowance,
    Trip,
    TripStop,
    Vehicle,
    VehicleAvailability,
)
from app.schemas.planning import (
    AlertItem,
    DashboardSummary,
    FuelLedgerResponse,
    GeneratePlanRequest,
    PlanRunResponse,
    PlanRunSummaryResponse,
    StopDetail,
    TripCard,
    TripDetailResponse,
    TripResponse,
    ValidatePlanRequest,
    ValidatePlanResponse,
    VehicleAvailabilityResponse,
    ViolationItem,
)
from app.engine.types import (
    AllocatorInput,
    DistrictRef,
    OrderInput,
    OutletRef,
    ReferenceData,
    VehicleRef,
    VehicleSlot,
    WeeklyFuelLedger,
    TripPlan,
)
from app.engine.constants import (
    BUDGET_FRESH_MIN,
    BUDGET_STYLE_TECH_MIN,
    DeferralCode,
)
from app.engine.allocator import allocate
from app.engine.formula import (
    compute_trip_fuel,
    compute_trip_minutes,
    hhmm_to_minutes,
    minutes_to_hhmm,
)
from app.engine.timeline import compute_stop_etas
from app.engine.validator import validate_trip, validate_plan
from app.seed.day_generator import build_engine_reference_from_db
from app.services.notification_service import emit_event
from app.services.order_service import get_next_operating_date


def get_current_iso_week(target_date: date) -> Tuple[int, int]:
    iso_cal = target_date.isocalendar()
    return iso_cal.year, iso_cal.week


def generate_plan_service(
    db: Session, req: GeneratePlanRequest, user_id: str
) -> PlanRunResponse:
    now_dt = business_now()
    delivery_date = req.delivery_date
    depot_id = req.depot_id
    iso_year, iso_week = get_current_iso_week(delivery_date)

    # 1. Validate operating day
    cal = db.query(CalendarDay).filter_by(date=delivery_date).first()
    if not cal or not cal.is_operating:
        raise NotOperatingDayException(f"Delivery date {delivery_date} is not an operating day")

    ref = build_engine_reference_from_db(db)

    # 2. Existing locked trips if regenerating
    locked_slots: List[VehicleSlot] = []
    if req.regenerate:
        # Keep CONFIRMED or later trips locked
        locked_trips = (
            db.query(Trip)
            .filter(
                Trip.depot_id == depot_id,
                Trip.delivery_date == delivery_date,
                Trip.status.in_(["CONFIRMED", "LOADING", "BLOCKED", "LOADED", "IN_PROGRESS", "COMPLETED"]),
            )
            .all()
        )
        for lt in locked_trips:
            vref = ref.vehicles.get(lt.vehicle_id)
            if not vref:
                continue
            stops = db.query(TripStop).filter_by(trip_id=lt.id).order_by(TripStop.seq.asc()).all()
            trip_orders = []
            used_weight = 0.0
            used_vol = 0.0
            for s in stops:
                ord_rec = db.query(Order).filter_by(id=s.order_id).first()
                if ord_rec:
                    out = ref.outlets.get(ord_rec.outlet_id)
                    trip_orders.append(OrderInput(
                        order_id=ord_rec.id,
                        outlet_id=ord_rec.outlet_id,
                        brand=ord_rec.brand if hasattr(ord_rec, 'brand') else (out.brand if out else lt.brand),
                        district=out.district if out else lt.district,
                        depot=depot_id,
                        temp_requirement=ord_rec.temp_requirement,
                        order_weight_kg=ord_rec.order_weight_kg,
                        order_volume_m3=ord_rec.order_volume_m3,
                    ))
                    used_weight += ord_rec.order_weight_kg
                    used_vol += ord_rec.order_volume_m3

            locked_slots.append(VehicleSlot(
                vehicle_id=lt.vehicle_id,
                trip_no=lt.trip_no,
                vehicle_ref=vref,
                used_weight_kg=used_weight,
                used_volume_m3=used_vol,
                current_trip_minutes=float(lt.est_minutes or 0),
                current_fuel_l=float(lt.est_fuel_l or 0),
                orders=trip_orders,
                brand=lt.brand,
                district=lt.district,
                is_locked=True,
            ))

        # Delete existing DRAFT trips and stops cleanly
        draft_trips = (
            db.query(Trip)
            .filter(
                Trip.depot_id == depot_id,
                Trip.delivery_date == delivery_date,
                Trip.status == "DRAFT",
            )
            .all()
        )
        draft_trip_ids = [dt.id for dt in draft_trips]
        if draft_trip_ids:
            # Revert order statuses for orders on these draft trips to SUBMITTED
            draft_stops = db.query(TripStop).filter(TripStop.trip_id.in_(draft_trip_ids)).all()
            for ds in draft_stops:
                ord_rec = db.query(Order).filter_by(id=ds.order_id).first()
                if ord_rec and ord_rec.status == "PLANNED":
                    ord_rec.status = "SUBMITTED"
            db.flush()

            # Delete TripStops first to satisfy foreign key constraint
            db.query(TripStop).filter(TripStop.trip_id.in_(draft_trip_ids)).delete(synchronize_session=False)
            db.flush()

            # Delete Trips
            db.query(Trip).filter(Trip.id.in_(draft_trip_ids)).delete(synchronize_session=False)
            db.flush()

    # 3. Fetch Available Vehicles
    avail_records = (
        db.query(VehicleAvailability)
        .filter(VehicleAvailability.date == delivery_date)
        .all()
    )
    avail_map = {av.vehicle_id: av.status for av in avail_records}
    available_vids = [
        v.id for v in db.query(Vehicle).filter_by(depot_id=depot_id).all()
        if avail_map.get(v.id, "available") == "available"
    ]

    # 4. Fetch Fuel Ledger
    fuel_records = (
        db.query(FuelLedger)
        .filter_by(iso_year=iso_year, iso_week=iso_week)
        .all()
    )
    fuel_ledger = [
        WeeklyFuelLedger(
            vehicle_id=fl.vehicle_id,
            iso_year=fl.iso_year,
            iso_week=fl.iso_week,
            litres_committed=fl.litres_committed,
        )
        for fl in fuel_records
    ]

    # 5. Fetch SUBMITTED Orders for this depot and delivery date (including re-queued orders)
    submitted_orders = (
        db.query(Order)
        .join(Outlet, Order.outlet_id == Outlet.id)
        .filter(
            Outlet.depot_id == depot_id,
            Order.delivery_date == delivery_date,
            Order.status == "SUBMITTED",
        )
        .all()
    )

    # If regenerating, clean up existing deferrals for these orders so optimizer can re-evaluate
    if req.regenerate:
        for so in submitted_orders:
            db.query(Deferral).filter_by(order_id=so.id, from_delivery_date=delivery_date).delete()
        db.flush()


    # Fetch outlet service states for priority history
    service_states = {
        st.outlet_id: st for st in db.query(OutletServiceState).all()
    }

    order_inputs: List[OrderInput] = []
    for ord_rec in submitted_orders:
        out = ref.outlets.get(ord_rec.outlet_id)
        if not out:
            continue
        st = service_states.get(ord_rec.outlet_id)
        is_def_yesterday = (
            st.last_deferred_date == (delivery_date - timedelta(days=1))
            if (st and st.last_deferred_date)
            else (ord_rec.deferral_count > 0)
        )
        dsls = (delivery_date - st.last_served_date).days if (st and st.last_served_date) else 1

        order_inputs.append(OrderInput(
            order_id=ord_rec.id,
            outlet_id=ord_rec.outlet_id,
            brand=out.brand,
            district=out.district,
            depot=depot_id,
            temp_requirement=ord_rec.temp_requirement,
            order_weight_kg=ord_rec.order_weight_kg,
            order_volume_m3=ord_rec.order_volume_m3,
            deferred_yesterday=is_def_yesterday,
            days_since_last_served=dsls,
        ))

    # 6. Execute allocation engine
    alloc_inp = AllocatorInput(
        depot=depot_id,
        delivery_date=str(delivery_date),
        iso_year=iso_year,
        iso_week=iso_week,
        is_operating=True,
        orders=order_inputs,
        available_vehicle_ids=available_vids,
        locked_slots=locked_slots,
        fuel_ledger=fuel_ledger,
        reference=ref,
        reload_buffer_min=settings.RELOAD_BUFFER_MIN,
    )

    alloc_out = allocate(alloc_inp)

    # 7. Create / Update PlanRun
    plan_run_id = f"PLAN-{depot_id[:3].upper()}-{delivery_date.strftime('%Y%m%d')}"
    plan_run = db.query(PlanRun).filter_by(id=plan_run_id).first()
    if not plan_run:
        plan_run = PlanRun(
            id=plan_run_id,
            depot_id=depot_id,
            delivery_date=delivery_date,
            status="OPEN",
            version=1,
            generated_by=user_id,
            generated_at=now_dt,
            summary_json={},
        )
        db.add(plan_run)
    else:
        plan_run.version += 1
        plan_run.generated_at = now_dt
        plan_run.generated_by = user_id
    db.flush()

    # 8. Persist new Trips and Stops
    for trip_plan in alloc_out.trips:
        # Check if already exists (e.g. locked)
        trip_id = f"TRIP-{plan_run.id}-{trip_plan.vehicle_id}-{trip_plan.trip_no}"
        existing_trip = db.query(Trip).filter_by(id=trip_id).first()
        if existing_trip:
            continue

        new_trip = Trip(
            id=trip_id,
            plan_run_id=plan_run.id,
            vehicle_id=trip_plan.vehicle_id,
            depot_id=depot_id,
            delivery_date=delivery_date,
            trip_no=trip_plan.trip_no,
            brand=trip_plan.brand,
            district=trip_plan.district,
            status="DRAFT",
            plan_version=1,
            depart_time=trip_plan.depart_time,
            est_minutes=int(round(trip_plan.trip_minutes)),
            est_km=0.0,
            est_fuel_l=round(trip_plan.est_fuel_l, 2),
        )
        db.add(new_trip)
        db.flush()

        for stop in trip_plan.stops:
            stop_id = f"STOP-{new_trip.id}-{stop.seq}"
            db.add(TripStop(
                id=stop_id,
                trip_id=new_trip.id,
                order_id=stop.order_id,
                seq=stop.seq,
                eta=stop.eta_clock,
                service_start_est=minutes_to_hhmm(stop.service_start_min),
                service_min=int(stop.service_end_min - stop.service_start_min),
                status="PENDING",
                receipt_status="NONE",
            ))
            # Update order status to PLANNED
            ord_obj = db.query(Order).filter_by(id=stop.order_id).first()
            if ord_obj:
                ord_obj.status = "PLANNED"

        # Update FuelLedger
        fl_rec = db.query(FuelLedger).filter_by(
            vehicle_id=trip_plan.vehicle_id, iso_year=iso_year, iso_week=iso_week
        ).first()
        if fl_rec:
            fl_rec.litres_committed += trip_plan.est_fuel_l
        else:
            db.add(FuelLedger(
                vehicle_id=trip_plan.vehicle_id,
                iso_year=iso_year,
                iso_week=iso_week,
                litres_committed=trip_plan.est_fuel_l,
            ))

    # 9. Persist Deferrals
    for def_rec in alloc_out.deferrals:
        # Check if already deferred
        def_id = f"DEF-{def_rec.order_id}-{delivery_date.strftime('%Y%m%d')}"
        existing_def = db.query(Deferral).filter_by(id=def_id).first()
        if not existing_def:
            db.add(Deferral(
                id=def_id,
                order_id=def_rec.order_id,
                from_delivery_date=delivery_date,
                reason_code=def_rec.reason_code,
                reason_class=def_rec.reason_class,
                reason_text=def_rec.reason_text,
                consequence_text=def_rec.consequence_text,
                details_json=def_rec.details,
                decided_by="engine",
                decided_at=now_dt,
                notified_at=now_dt,
            ))
            ord_obj = db.query(Order).filter_by(id=def_rec.order_id).first()
            if ord_obj:
                ord_obj.status = "DEFERRED"
                ord_obj.deferral_count += 1

                # Update service state
                st = db.query(OutletServiceState).filter_by(outlet_id=ord_obj.outlet_id).first()
                if st:
                    st.last_deferred_date = delivery_date
                    st.consecutive_deferrals += 1
                else:
                    db.add(OutletServiceState(
                        outlet_id=ord_obj.outlet_id,
                        last_deferred_date=delivery_date,
                        consecutive_deferrals=1,
                    ))

    db.commit()
    db.refresh(plan_run)

    emit_event(
        db=db,
        event_type="plan.generated",
        payload={"plan_run_id": plan_run.id, "depot_id": depot_id, "trips_count": len(alloc_out.trips)},
        audience_role="dispatcher",
        audience_scope=depot_id,
        notification_message=f"Plan generated for {depot_id} ({delivery_date}) with {len(alloc_out.trips)} trips",
    )
    db.commit()

    return PlanRunResponse.model_validate(plan_run)


def list_plans_service(db: Session, depot_id: Optional[str] = None) -> List[PlanRunResponse]:
    query = db.query(PlanRun)
    if depot_id:
        query = query.filter_by(depot_id=depot_id)
    plans = query.order_by(PlanRun.delivery_date.desc()).all()
    return [PlanRunResponse.model_validate(p) for p in plans]


def get_plan_run_trips_service(db: Session, plan_run_id: str, depot_id: Optional[str] = None) -> List[TripDetailResponse]:
    query = db.query(Trip).filter_by(plan_run_id=plan_run_id)
    if depot_id:
        query = query.filter_by(depot_id=depot_id)
    trips = query.order_by(Trip.trip_no.asc(), Trip.vehicle_id.asc()).all()

    ref = build_engine_reference_from_db(db)
    outlet_names = {o.id: o.display_name for o in db.query(Outlet).all()}
    result = []
    for t in trips:
        v = ref.vehicles.get(t.vehicle_id)
        stops = db.query(TripStop).filter_by(trip_id=t.id).order_by(TripStop.seq.asc()).all()

        used_weight = 0.0
        used_vol = 0.0
        stop_details = []
        for s in stops:
            ord_rec = db.query(Order).filter_by(id=s.order_id).first()
            out = ref.outlets.get(ord_rec.outlet_id) if ord_rec else None
            if ord_rec:
                used_weight += ord_rec.order_weight_kg
                used_vol += ord_rec.order_volume_m3
                stop_details.append(StopDetail(
                    id=s.id,
                    trip_id=s.trip_id,
                    order_id=s.order_id,
                    seq=s.seq,
                    outlet_id=ord_rec.outlet_id,
                    outlet_name=outlet_names.get(ord_rec.outlet_id, ord_rec.outlet_id),
                    district=out.district if out else t.district,
                    dock_type=out.dock_type if out else "rear_dock",
                    parking_constraint=out.parking_constraint if out else "normal",
                    order_units=ord_rec.order_units,
                    order_weight_kg=ord_rec.order_weight_kg,
                    order_volume_m3=ord_rec.order_volume_m3,
                    window_open_time=out.window_open_time if out else "03:00",
                    window_close_time=out.window_close_time if out else "08:00",
                    eta=s.eta,
                    service_start_est=s.service_start_est,
                    service_min=s.service_min,
                    status=s.status,
                    receipt_status=s.receipt_status,
                    arrived_at=s.arrived_at,
                    completed_at=s.completed_at,
                    outcome=s.outcome,
                    quantity_delivered=s.quantity_delivered,
                    received_by=s.received_by,
                    outcome_note=s.outcome_note,
                ))

        card = TripCard(
            id=t.id,
            plan_run_id=t.plan_run_id,
            delivery_date=t.delivery_date,
            trip_no=t.trip_no,
            brand=t.brand,
            district=t.district,
            depot_id=t.depot_id,
            vehicle_id=t.vehicle_id,
            vehicle_type=v.type if v else "truck",
            vehicle_temp=v.temp if v else "ambient",
            stop_count=len(stops),
            depart_time=t.depart_time,
            plan_version=t.plan_version,
            status=t.status,
            weight_used_kg=round(used_weight, 1),
            weight_cap_kg=v.weight_cap_kg if v else 0.0,
            volume_used_m3=round(used_vol, 2),
            volume_cap_m3=v.volume_cap_m3 if v else 0.0,
            est_minutes=t.est_minutes,
            est_fuel_l=t.est_fuel_l,
            time_budget_min=BUDGET_FRESH_MIN if t.brand == "Fresh" else BUDGET_STYLE_TECH_MIN,
        )
        result.append(TripDetailResponse(trip=card, stops=stop_details))
    return result


def validate_plan_service(db: Session, req: ValidatePlanRequest) -> ValidatePlanResponse:
    plan_run = db.query(PlanRun).filter_by(id=req.plan_run_id).first()
    if not plan_run:
        raise AppException(code="PLAN_NOT_FOUND", message=f"Plan run {req.plan_run_id} not found", status_code=404)

    trips = db.query(Trip).filter_by(plan_run_id=plan_run.id).all()
    ref = build_engine_reference_from_db(db)

    trip_plans: List[TripPlan] = []
    for t in trips:
        stops = db.query(TripStop).filter_by(trip_id=t.id).order_by(TripStop.seq.asc()).all()
        orders = []
        for s in stops:
            ord_rec = db.query(Order).filter_by(id=s.order_id).first()
            if ord_rec:
                orders.append(OrderInput(
                    order_id=ord_rec.id,
                    outlet_id=ord_rec.outlet_id,
                    brand=t.brand,
                    district=t.district,
                    depot=t.depot_id,
                    temp_requirement=ord_rec.temp_requirement,
                    order_weight_kg=ord_rec.order_weight_kg,
                    order_volume_m3=ord_rec.order_volume_m3,
                ))

        trip_plans.append(TripPlan(
            trip_key=f"{t.vehicle_id}_trip{t.trip_no}",
            vehicle_id=t.vehicle_id,
            trip_no=t.trip_no,
            brand=t.brand,
            district=t.district,
            depot=t.depot_id,
            orders=orders,
        ))

    iso_year, iso_week = get_current_iso_week(plan_run.delivery_date)
    fuel_records = db.query(FuelLedger).filter_by(iso_year=iso_year, iso_week=iso_week).all()
    fuel_ledger = [
        WeeklyFuelLedger(vehicle_id=fl.vehicle_id, iso_year=fl.iso_year, iso_week=fl.iso_week, litres_committed=fl.litres_committed)
        for fl in fuel_records
    ]

    inp = AllocatorInput(
        depot=plan_run.depot_id,
        delivery_date=str(plan_run.delivery_date),
        iso_year=iso_year,
        iso_week=iso_week,
        is_operating=True,
        orders=[],
        available_vehicle_ids=[v.id for v in db.query(Vehicle).filter_by(depot_id=plan_run.depot_id).all()],
        locked_slots=[],
        fuel_ledger=fuel_ledger,
        reference=ref,
    )

    vehicle_statuses = {v.id: "available" for v in db.query(Vehicle).all()}
    val_res = validate_plan(trip_plans, inp, vehicle_statuses, {})

    violations = [
        ViolationItem(rule=v.rule, message=v.message, actual=v.actual, limit=v.limit)
        for v in val_res.violations
    ]
    return ValidatePlanResponse(valid=val_res.is_valid, violations=violations)


def add_order_to_trip_service(db: Session, trip_id: str, order_id: str) -> TripResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    order = db.query(Order).filter_by(id=order_id).first()
    if not order:
        raise AppException(code="ORDER_NOT_FOUND", message=f"Order {order_id} not found", status_code=404)

    # Check if order is already assigned
    existing_stop = db.query(TripStop).filter_by(order_id=order_id).first()
    if existing_stop:
        raise InvalidTransitionException(f"Order {order_id} is already assigned to trip {existing_stop.trip_id}")

    ref = build_engine_reference_from_db(db)
    vref = ref.vehicles.get(trip.vehicle_id)

    # Build prospective trip orders
    current_stops = db.query(TripStop).filter_by(trip_id=trip.id).order_by(TripStop.seq.asc()).all()
    current_orders = []
    for s in current_stops:
        o = db.query(Order).filter_by(id=s.order_id).first()
        if o:
            current_orders.append(OrderInput(
                order_id=o.id,
                outlet_id=o.outlet_id,
                brand=trip.brand,
                district=trip.district,
                depot=trip.depot_id,
                temp_requirement=o.temp_requirement,
                order_weight_kg=o.order_weight_kg,
                order_volume_m3=o.order_volume_m3,
            ))

    out = ref.outlets.get(order.outlet_id)
    new_order_input = OrderInput(
        order_id=order.id,
        outlet_id=order.outlet_id,
        brand=out.brand if out else trip.brand,
        district=out.district if out else trip.district,
        depot=trip.depot_id,
        temp_requirement=order.temp_requirement,
        order_weight_kg=order.order_weight_kg,
        order_volume_m3=order.order_volume_m3,
    )

    prospective_trip = TripPlan(
        trip_key=f"{trip.vehicle_id}_trip{trip.trip_no}",
        vehicle_id=trip.vehicle_id,
        trip_no=trip.trip_no,
        brand=trip.brand,
        district=trip.district,
        depot=trip.depot_id,
        orders=current_orders + [new_order_input],
    )

    # Validate
    val = validate_trip(
        trip=prospective_trip,
        ref=ref,
        vehicle_ref=vref,
        vehicle_status="available",
        is_operating=True,
        fuel_already_committed_l=0.0,
        fresh_budget_used=0.0,
        style_tech_budget_used=0.0,
        trip_count_for_vehicle=trip.trip_no,
    )
    if not val.is_valid:
        violation_dicts = [{"rule": v.rule, "message": v.message, "actual": v.actual, "limit": v.limit} for v in val.violations]
        raise ConstraintViolationException(
            message=f"Cannot add order {order_id} to trip {trip_id}: constraint violation",
            violations=violation_dicts,
        )

    # Insert stop
    new_seq = len(current_stops) + 1
    stop_id = f"STOP-{trip.id}-{new_seq}"
    db.add(TripStop(
        id=stop_id,
        trip_id=trip.id,
        order_id=order.id,
        seq=new_seq,
        service_min=15,
        status="PENDING",
        receipt_status="NONE",
    ))

    # Update order status
    order.status = "SCHEDULED" if trip.status == "CONFIRMED" else "PLANNED"

    # Remove any existing deferral record
    db.query(Deferral).filter_by(order_id=order.id).delete()

    # Bump plan_version if confirmed
    if trip.status == "CONFIRMED":
        trip.plan_version += 1

    # Recalculate trip minutes and fuel
    dist = ref.districts[trip.district]
    trip.est_minutes = int(round(compute_trip_minutes(prospective_trip.orders, dist, ref, trip.brand)))
    trip.est_fuel_l = round(compute_trip_fuel(len(prospective_trip.orders), dist, vref.km_per_l), 2)

    db.commit()
    db.refresh(trip)

    emit_event(
        db=db,
        event_type="trip.updated",
        payload={"trip_id": trip.id, "action": "add_order", "order_id": order.id},
        audience_role="dispatcher",
        audience_scope=trip.depot_id,
    )
    db.commit()

    return TripResponse.model_validate(trip)


def remove_order_from_trip_service(db: Session, trip_id: str, order_id: str) -> TripResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    stop = db.query(TripStop).filter_by(trip_id=trip_id, order_id=order_id).first()
    if not stop:
        raise AppException(code="STOP_NOT_FOUND", message=f"Order {order_id} is not on trip {trip_id}", status_code=404)

    db.delete(stop)

    order = db.query(Order).filter_by(id=order_id).first()
    if order:
        order.status = "SUBMITTED"

    if trip.status == "CONFIRMED":
        trip.plan_version += 1

    # Re-sequence remaining stops
    remaining_stops = db.query(TripStop).filter_by(trip_id=trip_id).order_by(TripStop.seq.asc()).all()
    for idx, s in enumerate(remaining_stops, start=1):
        s.seq = idx

    ref = build_engine_reference_from_db(db)
    vref = ref.vehicles.get(trip.vehicle_id)
    dist = ref.districts.get(trip.district)
    if dist and vref and remaining_stops:
        orders_rem = [
            OrderInput(
                order_id=s.order_id, outlet_id="", brand=trip.brand,
                district=trip.district, depot=trip.depot_id, temp_requirement="ambient",
                order_weight_kg=100.0, order_volume_m3=0.5
            )
            for s in remaining_stops
        ]
        trip.est_minutes = int(round(compute_trip_minutes(orders_rem, dist, ref, trip.brand)))
        trip.est_fuel_l = round(compute_trip_fuel(len(remaining_stops), dist, vref.km_per_l), 2)
    else:
        trip.est_minutes = 0
        trip.est_fuel_l = 0.0

    db.commit()
    db.refresh(trip)

    emit_event(
        db=db,
        event_type="trip.updated",
        payload={"trip_id": trip.id, "action": "remove_order", "order_id": order_id},
        audience_role="dispatcher",
        audience_scope=trip.depot_id,
    )
    db.commit()

    return TripResponse.model_validate(trip)


def confirm_trip_service(db: Session, trip_id: str, user_id: str) -> TripDetailResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    if trip.status != "DRAFT":
        raise InvalidTransitionException(f"Cannot confirm trip in state {trip.status}; must be DRAFT")

    ref = build_engine_reference_from_db(db)
    vref = ref.vehicles.get(trip.vehicle_id)

    stops = db.query(TripStop).filter_by(trip_id=trip.id).order_by(TripStop.seq.asc()).all()
    orders = []
    for s in stops:
        o = db.query(Order).filter_by(id=s.order_id).first()
        if o:
            orders.append(OrderInput(
                order_id=o.id,
                outlet_id=o.outlet_id,
                brand=trip.brand,
                district=trip.district,
                depot=trip.depot_id,
                temp_requirement=o.temp_requirement,
                order_weight_kg=o.order_weight_kg,
                order_volume_m3=o.order_volume_m3,
            ))

    trip_plan = TripPlan(
        trip_key=f"{trip.vehicle_id}_trip{trip.trip_no}",
        vehicle_id=trip.vehicle_id,
        trip_no=trip.trip_no,
        brand=trip.brand,
        district=trip.district,
        depot=trip.depot_id,
        orders=orders,
    )

    val = validate_trip(
        trip=trip_plan,
        ref=ref,
        vehicle_ref=vref,
        vehicle_status="available",
        is_operating=True,
        fuel_already_committed_l=0.0,
        fresh_budget_used=0.0,
        style_tech_budget_used=0.0,
        trip_count_for_vehicle=trip.trip_no,
    )
    if not val.is_valid:
        violation_dicts = [{"rule": v.rule, "message": v.message, "actual": v.actual, "limit": v.limit} for v in val.violations]
        raise ConstraintViolationException(
            message=f"Cannot confirm trip {trip_id}: constraint violation",
            violations=violation_dicts,
        )

    now = business_now()
    trip.status = "CONFIRMED"
    trip.confirmed_by = user_id
    trip.confirmed_at = now

    # In one transaction: move all orders on the trip to SCHEDULED (D19)
    for s in stops:
        ord_obj = db.query(Order).filter_by(id=s.order_id).first()
        if ord_obj:
            ord_obj.status = "SCHEDULED"
            emit_event(
                db=db,
                event_type="order.scheduled",
                payload={"order_id": ord_obj.id, "trip_id": trip.id, "status": "SCHEDULED"},
                audience_role="store_manager",
                audience_scope=ord_obj.outlet_id,
                notification_message=f"Order {ord_obj.id} has been scheduled on trip {trip.id}",
            )

    db.commit()
    db.refresh(trip)

    emit_event(
        db=db,
        event_type="trip.confirmed",
        payload={"trip_id": trip.id, "confirmed_by": user_id},
        audience_role="loader",
        audience_scope=trip.depot_id,
        notification_message=f"Trip {trip.id} confirmed and ready for loading",
    )
    db.commit()

    # Return TripDetailResponse
    details = get_plan_run_trips_service(db, trip.plan_run_id)
    matching = next((d for d in details if d.trip.id == trip.id), None)
    if matching:
        return matching
    raise AppException(code="TRIP_NOT_FOUND", message=f"Trip detail not found", status_code=404)


def cancel_trip_service(db: Session, trip_id: str) -> TripResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    if trip.status not in ("DRAFT", "CONFIRMED", "LOADING", "BLOCKED"):
        raise InvalidTransitionException(f"Cannot cancel trip in state {trip.status}")

    trip.status = "CANCELLED"

    # Reset orders to SUBMITTED
    stops = db.query(TripStop).filter_by(trip_id=trip.id).all()
    for s in stops:
        ord_obj = db.query(Order).filter_by(id=s.order_id).first()
        if ord_obj and ord_obj.status in ("PLANNED", "SCHEDULED"):
            ord_obj.status = "SUBMITTED"

    db.commit()
    db.refresh(trip)

    emit_event(
        db=db,
        event_type="trip.updated",
        payload={"trip_id": trip.id, "action": "cancelled"},
        audience_role="dispatcher",
        audience_scope=trip.depot_id,
    )
    db.commit()

    return TripResponse.model_validate(trip)


def close_plan_run_service(db: Session, depot_id: str, user_id: str) -> PlanRunResponse:
    # Find latest open plan run
    plan_run = (
        db.query(PlanRun)
        .filter_by(depot_id=depot_id, status="OPEN")
        .order_by(PlanRun.delivery_date.desc())
        .first()
    )
    if not plan_run:
        raise AppException(code="NO_OPEN_PLAN", message=f"No open plan run found for depot {depot_id}", status_code=404)

    delivery_date = plan_run.delivery_date

    # Check that all orders for this delivery date and depot are either assigned to a trip or deferred
    unassigned = (
        db.query(Order)
        .join(Outlet, Order.outlet_id == Outlet.id)
        .filter(
            Outlet.depot_id == depot_id,
            Order.delivery_date == delivery_date,
            Order.status == "SUBMITTED",
        )
        .count()
    )
    if unassigned > 0:
        raise InvalidTransitionException(
            f"Cannot close run: {unassigned} order(s) remain unassigned. Every order must be placed on a trip or deferred."
        )

    # Roll forward deferred orders to next operating day
    next_op_date = get_next_operating_date(db, delivery_date)
    if not next_op_date:
        next_op_date = delivery_date + timedelta(days=1)

    deferred_orders = (
        db.query(Order)
        .join(Outlet, Order.outlet_id == Outlet.id)
        .filter(
            Outlet.depot_id == depot_id,
            Order.delivery_date == delivery_date,
            Order.status == "DEFERRED",
        )
        .all()
    )

    for do in deferred_orders:
        do.status = "SUBMITTED"
        do.delivery_date = next_op_date
        do.rolled_over = True
        # update outlet service state
        st = db.query(OutletServiceState).filter_by(outlet_id=do.outlet_id).first()
        if st:
            st.last_deferred_date = delivery_date

    plan_run.status = "CLOSED"
    db.commit()
    db.refresh(plan_run)

    emit_event(
        db=db,
        event_type="run.closed",
        payload={"plan_run_id": plan_run.id, "depot_id": depot_id, "carried_forward": len(deferred_orders)},
        audience_role="dispatcher",
        audience_scope=depot_id,
        notification_message=f"Plan run {plan_run.id} closed. {len(deferred_orders)} deferrals rolled to {next_op_date}",
    )
    db.commit()

    return PlanRunResponse.model_validate(plan_run)


def get_plans_summary_service(db: Session, depot_id: Optional[str] = None) -> PlanRunSummaryResponse:
    plan_run = (
        db.query(PlanRun)
        .filter_by(depot_id=depot_id)
        .order_by(PlanRun.delivery_date.desc())
        .first() if depot_id else db.query(PlanRun).order_by(PlanRun.delivery_date.desc()).first()
    )
    if not plan_run:
        plan_run_id = "PLAN-NONE"
        status = "OPEN"
        version = 1
    else:
        plan_run_id = plan_run.id
        status = plan_run.status
        version = plan_run.version

    target_date = plan_run.delivery_date if plan_run else date(2025, 8, 1)
    depot = depot_id or (plan_run.depot_id if plan_run else "Peliyagoda")

    trips = db.query(Trip).filter(Trip.depot_id == depot, Trip.delivery_date == target_date).all()
    orders_served = db.query(TripStop).join(Trip, TripStop.trip_id == Trip.id).filter(Trip.depot_id == depot, Trip.delivery_date == target_date).count()
    orders_deferred = db.query(Deferral).filter(Deferral.from_delivery_date == target_date).count()

    # Deferral counts by class & code
    def_records = db.query(Deferral).filter(Deferral.from_delivery_date == target_date).all()
    by_class = {}
    by_code = {}
    for d in def_records:
        by_class[d.reason_class] = by_class.get(d.reason_class, 0) + 1
        by_code[d.reason_code] = by_code.get(d.reason_code, 0) + 1

    # Capacity
    vehicles = db.query(Vehicle).filter_by(depot_id=depot).all()
    weight_cap = sum(v.weight_cap_kg for v in vehicles)
    vol_cap = sum(v.volume_cap_m3 for v in vehicles)
    used_weight = sum((t.est_minutes or 0) * 10 for t in trips)  # placeholder approximate or exact from orders
    # Calculate exact used weight and volume from stops
    all_stops = db.query(TripStop).join(Trip, TripStop.trip_id == Trip.id).filter(Trip.depot_id == depot, Trip.delivery_date == target_date).all()
    exact_weight = 0.0
    exact_vol = 0.0
    for s in all_stops:
        o = db.query(Order).filter_by(id=s.order_id).first()
        if o:
            exact_weight += o.order_weight_kg
            exact_vol += o.order_volume_m3

    # Reefer
    reefer_vehicles = [v for v in vehicles if v.temp in ("reefer", "chilled")]
    chilled_orders = db.query(Order).join(Outlet, Order.outlet_id == Outlet.id).filter(Outlet.depot_id == depot, Order.delivery_date == target_date, Order.temp_requirement == "chilled").count()
    chilled_served = db.query(TripStop).join(Trip, TripStop.trip_id == Trip.id).join(Order, TripStop.order_id == Order.id).filter(Trip.depot_id == depot, Trip.delivery_date == target_date, Order.temp_requirement == "chilled").count()

    # Fuel
    iso_year, iso_week = get_current_iso_week(target_date)
    fuel_list = []
    for v in vehicles[:5]:
        fl = db.query(FuelLedger).filter_by(vehicle_id=v.id, iso_year=iso_year, iso_week=iso_week).first()
        comm = fl.litres_committed if fl else 0.0
        fuel_list.append({
            "vehicle_id": v.id,
            "quota_l": v.weekly_fuel_quota_l,
            "committed_l": round(comm, 1),
            "remaining_l": round(max(0.0, v.weekly_fuel_quota_l - comm), 1),
        })

    return PlanRunSummaryResponse(
        plan_run_id=plan_run_id,
        status=status,
        version=version,
        trips=len(trips),
        orders_served=orders_served,
        orders_deferred=orders_deferred,
        deferred_counts={"by_class": by_class, "by_code": by_code},
        capacity={
            "weight_used_kg": round(exact_weight, 1),
            "weight_cap_kg": round(weight_cap, 1),
            "volume_used_m3": round(exact_vol, 2),
            "volume_cap_m3": round(vol_cap, 2),
        },
        reefer={
            "chilled_demand": chilled_orders,
            "chilled_used": chilled_served,
            "chilled_available": len(reefer_vehicles),
        },
        fuel=fuel_list,
        constraint_health={"compliant": True, "violations": []},
    )


def get_dashboard_service(db: Session, depot_id: Optional[str] = None) -> DashboardSummary:
    now_dt = business_now()
    depot = depot_id or "Peliyagoda"
    delivery_date = date(2025, 8, 1)

    cutoff_dt = datetime.combine(delivery_date - timedelta(days=1), time(16, 0), tzinfo=now_dt.tzinfo)
    mins_remaining = max(0, int((cutoff_dt - now_dt).total_seconds() / 60))
    cutoff_passed = now_dt >= cutoff_dt

    orders = db.query(Order).join(Outlet, Order.outlet_id == Outlet.id).filter(Outlet.depot_id == depot, Order.delivery_date == delivery_date).all()
    by_brand = {"Fresh": 0, "Style": 0, "Tech": 0}
    unassigned = 0
    planned = 0
    deferred = 0
    for o in orders:
        out = db.query(Outlet).filter_by(id=o.outlet_id).first()
        b = out.brand if out else "Fresh"
        by_brand[b] = by_brand.get(b, 0) + 1
        if o.status == "SUBMITTED":
            unassigned += 1
        elif o.status in ("PLANNED", "SCHEDULED", "LOADED", "IN_TRANSIT", "DELIVERED"):
            planned += 1
        elif o.status == "DEFERRED":
            deferred += 1

    vehicles = db.query(Vehicle).filter_by(depot_id=depot).all()
    avail_records = db.query(VehicleAvailability).filter_by(date=delivery_date).all()
    avail_map = {av.vehicle_id: av.status for av in avail_records}
    in_ws = sum(1 for v in vehicles if avail_map.get(v.id) == "in_workshop")
    avail = len(vehicles) - in_ws

    trips = db.query(Trip).filter_by(depot_id=depot, delivery_date=delivery_date).all()
    active_trips_list = []
    for t in trips:
        stops = db.query(TripStop).filter_by(trip_id=t.id).all()
        completed = sum(1 for s in stops if s.status == "DELIVERED")
        active_trips_list.append({
            "trip_id": t.id,
            "vehicle_id": t.vehicle_id,
            "status": t.status,
            "stops_completed": completed,
            "stops_total": len(stops),
        })

    alerts = [
        AlertItem(
            id="ALT-001",
            type="capacity_shortage",
            severity="warning",
            status="open",
            entity_ref={"type": "depot", "id": depot},
            message="Chilled demand exceeds single-trip reefer capacity on peak day",
            created_at=now_dt,
        )
    ]

    return DashboardSummary(
        date=delivery_date,
        depot_id=depot,
        business_now=now_dt,
        cutoff={
            "cutoff_at": cutoff_dt.isoformat(),
            "minutes_remaining": mins_remaining,
            "passed": cutoff_passed,
        },
        orders={
            "total": len(orders),
            "by_brand": by_brand,
            "unassigned": unassigned,
            "planned": planned,
            "deferred": deferred,
        },
        planning_progress={
            "planned": planned,
            "total": len(orders),
        },
        vehicles={
            "total": len(vehicles),
            "available": avail,
            "in_workshop": in_ws,
            "allocated": len(trips),
            "loading": 0,
            "active": 0,
        },
        alerts=alerts,
        active_trips=active_trips_list,
    )


def get_fuel_state_service(db: Session, depot_id: Optional[str] = None) -> List[FuelLedgerResponse]:
    target_date = date(2025, 8, 1)
    iso_year, iso_week = get_current_iso_week(target_date)

    query = db.query(FuelLedger).filter_by(iso_year=iso_year, iso_week=iso_week)
    if depot_id:
        query = query.join(Vehicle, FuelLedger.vehicle_id == Vehicle.id).filter(Vehicle.depot_id == depot_id)
    records = query.all()
    return [FuelLedgerResponse.model_validate(r) for r in records]


def get_fleet_availability_service(
    db: Session, depot_id: Optional[str] = None, target_date: Optional[date] = None
) -> List[VehicleAvailabilityResponse]:
    d = target_date or date(2025, 8, 1)
    query = db.query(VehicleAvailability).filter_by(date=d)
    if depot_id:
        query = query.join(Vehicle, VehicleAvailability.vehicle_id == Vehicle.id).filter(Vehicle.depot_id == depot_id)
    records = query.all()
    return [VehicleAvailabilityResponse.model_validate(r) for r in records]


def get_dispatch_queue_service(db: Session, depot_id: Optional[str] = None) -> List[Order]:
    query = db.query(Order)
    if depot_id:
        query = query.join(Outlet, Order.outlet_id == Outlet.id).filter(Outlet.depot_id == depot_id)
    return query.order_by(Order.delivery_date.asc(), Order.placed_at.asc()).all()

