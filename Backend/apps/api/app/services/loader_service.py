"""
Loader Service - Handles loading list generation, loading start, shortfall reporting/resolution,
and final load confirmation per D13, D14, D19, and D23.
"""

from datetime import datetime
import uuid
from typing import List, Optional
from sqlalchemy.orm import Session

from app.core.clock import business_now
from app.core.errors import (
    AppException,
    InvalidTransitionException,
    ValidationException,
)
from app.models.domain import (
    Deferral,
    LoadCheck,
    Order,
    Outlet,
    OutletServiceState,
    Trip,
    TripStop,
    Vehicle,
)
from app.schemas.field import (
    ConfirmLoadRequest,
    CreateLoadCheckRequest,
    LoadCheckResponse,
    LoadListResponse,
    ResolveLoadCheckRequest,
)
from app.schemas.planning import (
    StopDetail,
    TripCard,
    TripResponse,
)
from app.services.notification_service import emit_event
from app.engine.types import ReferenceData, VehicleRef, OutletRef


BUDGET_FRESH_MIN = 270
BUDGET_STYLE_TECH_MIN = 480


def build_trip_card(db: Session, trip: Trip) -> TripCard:
    vehicle = db.query(Vehicle).filter_by(id=trip.vehicle_id).first()
    stops = db.query(TripStop).filter_by(trip_id=trip.id).all()
    orders = db.query(Order).filter(Order.id.in_([s.order_id for s in stops])).all() if stops else []

    total_weight = sum(o.order_weight_kg for o in orders)
    total_volume = sum(o.order_volume_m3 for o in orders)

    return TripCard(
        id=trip.id,
        plan_run_id=trip.plan_run_id,
        delivery_date=trip.delivery_date,
        trip_no=trip.trip_no,
        brand=trip.brand,
        district=trip.district,
        depot_id=trip.depot_id,
        vehicle_id=trip.vehicle_id,
        vehicle_type=vehicle.type if vehicle else "truck",
        vehicle_temp=vehicle.temp if vehicle else "ambient",
        stop_count=len(stops),
        depart_time=trip.depart_time,
        plan_version=trip.plan_version,
        status=trip.status,
        weight_used_kg=round(total_weight, 1),
        weight_cap_kg=vehicle.weight_cap_kg if vehicle else 0.0,
        volume_used_m3=round(total_volume, 2),
        volume_cap_m3=vehicle.volume_cap_m3 if vehicle else 0.0,
        est_minutes=trip.est_minutes,
        est_fuel_l=trip.est_fuel_l,
        time_budget_min=BUDGET_FRESH_MIN if trip.brand == "Fresh" else BUDGET_STYLE_TECH_MIN,
    )


def get_loading_trips_service(db: Session, depot_id: Optional[str] = None) -> List[TripCard]:
    query = db.query(Trip).filter(Trip.status.in_(["CONFIRMED", "LOADING", "BLOCKED", "LOADED"]))
    if depot_id:
        query = query.filter_by(depot_id=depot_id)
    trips = query.order_by(Trip.trip_no.asc(), Trip.vehicle_id.asc()).all()
    return [build_trip_card(db, t) for t in trips]


def get_trip_load_list_service(db: Session, trip_id: str) -> LoadListResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    card = build_trip_card(db, trip)
    stops = db.query(TripStop).filter_by(trip_id=trip.id).order_by(TripStop.seq.asc()).all()
    outlets = {o.id: o for o in db.query(Outlet).all()}

    delivery_seq: List[StopDetail] = []
    for s in stops:
        ord_rec = db.query(Order).filter_by(id=s.order_id).first()
        out = outlets.get(ord_rec.outlet_id) if ord_rec else None
        delivery_seq.append(StopDetail(
            id=s.id,
            trip_id=s.trip_id,
            order_id=s.order_id,
            seq=s.seq,
            outlet_id=ord_rec.outlet_id if ord_rec else "",
            outlet_name=out.display_name if out else "",
            district=out.district if out else trip.district,
            dock_type=out.dock_type if out else "rear_dock",
            parking_constraint=out.parking_constraint if out else "normal",
            order_units=ord_rec.order_units if ord_rec else 0,
            order_weight_kg=ord_rec.order_weight_kg if ord_rec else 0.0,
            order_volume_m3=ord_rec.order_volume_m3 if ord_rec else 0.0,
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

    reverse_load = list(reversed(delivery_seq))

    return LoadListResponse(
        plan_version=trip.plan_version,
        trip=card,
        delivery_sequence=delivery_seq,
        reverse_load_order=reverse_load,
    )


def start_trip_loading_service(db: Session, trip_id: str, user_id: str) -> TripResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    if trip.status == "LOADING":
        return TripResponse.model_validate(trip)

    if trip.status != "CONFIRMED":
        raise InvalidTransitionException(f"Cannot start loading for trip in status '{trip.status}'. Must be CONFIRMED.")

    trip.status = "LOADING"
    db.commit()
    db.refresh(trip)

    emit_event(
        db,
        event_type="loading.started",
        payload={"trip_id": trip.id, "depot_id": trip.depot_id, "started_by": user_id},
        audience_role="dispatcher",
        audience_scope=trip.depot_id,
        message=f"Loading started for trip {trip.id} ({trip.brand} {trip.district})",
    )

    return TripResponse.model_validate(trip)


def report_load_check_service(
    db: Session,
    trip_id: str,
    req: CreateLoadCheckRequest,
    user_id: str,
) -> LoadCheckResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    order = db.query(Order).filter_by(id=req.order_id).first()
    if not order:
        raise AppException(code="ORDER_NOT_FOUND", message=f"Order {req.order_id} not found", status_code=404)

    outlet = db.query(Outlet).filter_by(id=order.outlet_id).first()

    load_check_id = f"LC-{uuid.uuid4().hex[:8].upper()}"
    lc = LoadCheck(
        id=load_check_id,
        trip_id=trip.id,
        order_id=order.id,
        plan_version=req.plan_version,
        expected_qty=req.expected_qty,
        loaded_qty=req.loaded_qty,
        issue=req.issue,
        note=req.note,
        status="OPEN",
        reported_by=user_id,
        vehicle_id=trip.vehicle_id,
        outlet_id=order.outlet_id,
        outlet_name=outlet.display_name if outlet else order.outlet_id,
        bay=outlet.dock_type if outlet else "rear_dock",
    )
    db.add(lc)

    # Keep trip in LOADING status (do not block vehicle/trip confirmation)
    if trip.status in ["CONFIRMED", "BLOCKED"]:
        trip.status = "LOADING"
    db.commit()
    db.refresh(lc)
    db.refresh(trip)

    emit_event(
        db,
        event_type="loading.shortfall",
        payload={
            "load_check_id": lc.id,
            "trip_id": trip.id,
            "order_id": order.id,
            "issue": req.issue,
            "expected_qty": req.expected_qty,
            "loaded_qty": req.loaded_qty,
            "depot_id": trip.depot_id,
        },
        audience_role="dispatcher",
        audience_scope=trip.depot_id,
        message=f"Loading shortfall on trip {trip.id}: {req.issue} stock for order {order.id}",
    )

    return LoadCheckResponse.model_validate(lc)


def resolve_load_check_service(
    db: Session,
    load_check_id: str,
    req: ResolveLoadCheckRequest,
    user_id: str,
) -> LoadCheckResponse:
    lc = db.query(LoadCheck).filter_by(id=load_check_id).first()
    if not lc:
        raise AppException(code="LOAD_CHECK_NOT_FOUND", message=f"Load check {load_check_id} not found", status_code=404)

    trip = db.query(Trip).filter_by(id=lc.trip_id).first()
    order = db.query(Order).filter_by(id=lc.order_id).first()

    lc.status = "RESOLVED"
    lc.resolution = req.resolution
    lc.resolved_by = user_id
    if req.note:
        lc.note = f"{lc.note}; {req.note}" if lc.note else req.note

    now_dt = business_now()

    if req.resolution in ("cancel_order", "reject_load"):
        if order:
            order.status = "CANCELLED"
            order.cancel_reason = f"Warehouse Shortfall ({lc.issue})"
            if req.note:
                order.note = f"{order.note or ''}\nCancel Note: {req.note}".strip()

            # Emit notification to Store Manager
            emit_event(
                db,
                event_type="order.cancelled",
                payload={"order_id": order.id, "reason": order.cancel_reason, "note": req.note},
                audience_role="store_manager",
                audience_scope=order.outlet_id,
                message=f"Order {order.id} cancelled in loading bay due to {lc.issue} stock. {req.note or ''}".strip(),
            )

        # Remove stop from trip so truck can depart
        stop = db.query(TripStop).filter_by(trip_id=trip.id, order_id=lc.order_id).first() if trip else None
        if stop:
            db.delete(stop)
            remaining = db.query(TripStop).filter_by(trip_id=trip.id).filter(TripStop.id != stop.id).order_by(TripStop.seq.asc()).all()
            for idx, s in enumerate(remaining, start=1):
                s.seq = idx

        if trip:
            trip.plan_version += 1

    elif req.resolution in ("defer_order", "accept_shortfall", "reassign_stock"):
        if order:
            order.status = "DEFERRED"
            order.deferral_count += 1
            def_id = f"DEF-{uuid.uuid4().hex[:8].upper()}"
            deferral = Deferral(
                id=def_id,
                order_id=order.id,
                from_delivery_date=trip.delivery_date if trip else now_dt.date(),
                reason_code="SHORTFALL",
                reason_class="OPERATIONAL",
                reason_text=f"Warehouse shortfall resolution: {lc.issue}",
                consequence_text="Order deferred due to missing/damaged warehouse stock",
                decided_by="dispatcher",
                decided_by_user=user_id,
                decided_at=now_dt,
            )
            db.add(deferral)

            oss = db.query(OutletServiceState).filter_by(outlet_id=order.outlet_id).first()
            if not oss:
                oss = OutletServiceState(outlet_id=order.outlet_id, consecutive_deferrals=1, last_deferred_date=now_dt.date())
                db.add(oss)
            else:
                oss.last_deferred_date = now_dt.date()
                oss.consecutive_deferrals += 1

            emit_event(
                db,
                event_type="order.deferred",
                payload={"order_id": order.id, "reason": lc.issue, "note": req.note},
                audience_role="store_manager",
                audience_scope=order.outlet_id,
                message=f"Order {order.id} deferred during loading: {lc.issue} stock. {req.note or ''}".strip(),
            )

        stop = db.query(TripStop).filter_by(trip_id=trip.id, order_id=lc.order_id).first() if trip else None
        if stop:
            db.delete(stop)
            remaining = db.query(TripStop).filter_by(trip_id=trip.id).filter(TripStop.id != stop.id).order_by(TripStop.seq.asc()).all()
            for idx, s in enumerate(remaining, start=1):
                s.seq = idx

        if trip:
            trip.plan_version += 1

    elif req.resolution == "replan_order":
        if order:
            order.status = "SUBMITTED"
        stop = db.query(TripStop).filter_by(trip_id=trip.id, order_id=lc.order_id).first() if trip else None
        if stop:
            db.delete(stop)
            remaining = db.query(TripStop).filter_by(trip_id=trip.id).filter(TripStop.id != stop.id).order_by(TripStop.seq.asc()).all()
            for idx, s in enumerate(remaining, start=1):
                s.seq = idx
        if trip:
            trip.plan_version += 1

    elif req.resolution == "proceed_partial":
        stop = db.query(TripStop).filter_by(trip_id=trip.id, order_id=lc.order_id).first() if trip else None
        if stop:
            stop.quantity_delivered = lc.loaded_qty
        if trip:
            trip.plan_version += 1

    if trip and trip.status == "BLOCKED":
        trip.status = "LOADING"

    db.commit()
    db.refresh(lc)

    emit_event(
        db,
        event_type="loading.shortfall_resolved",
        payload={
            "load_check_id": lc.id,
            "resolution": req.resolution,
            "trip_id": lc.trip_id,
            "order_id": lc.order_id,
        },
        audience_role="loader",
        audience_scope=trip.depot_id if trip else None,
        message=f"Loading shortfall resolved ({req.resolution}) for order {lc.order_id}",
    )

    return LoadCheckResponse.model_validate(lc)


def confirm_trip_load_service(
    db: Session,
    trip_id: str,
    req: ConfirmLoadRequest,
    user_id: str,
) -> TripResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    if req.plan_version != trip.plan_version:
        raise InvalidTransitionException(
            f"Cannot confirm load: plan version mismatch (request: {req.plan_version}, current: {trip.plan_version})"
        )

    if trip.status not in ["LOADING", "CONFIRMED", "LOADED", "BLOCKED"]:
        raise InvalidTransitionException(f"Cannot confirm load for trip in status '{trip.status}'")

    trip.status = "LOADED"
    # Transition all orders on this trip to LOADED
    stops = db.query(TripStop).filter_by(trip_id=trip.id).all()
    for s in stops:
        ord_obj = db.query(Order).filter_by(id=s.order_id).first()
        if ord_obj and ord_obj.status in ["SCHEDULED", "PLANNED"]:
            ord_obj.status = "LOADED"
            emit_event(
                db,
                event_type="order.loaded",
                payload={"order_id": ord_obj.id, "trip_id": trip.id, "status": "LOADED"},
                audience_role="store_manager",
                audience_scope=ord_obj.outlet_id,
                message=f"Order {ord_obj.id} has been loaded for delivery",
            )

    db.commit()
    db.refresh(trip)

    emit_event(
        db,
        event_type="trip.loaded",
        payload={"trip_id": trip.id, "depot_id": trip.depot_id, "confirmed_by": user_id},
        audience_role="driver",
        audience_scope=trip.vehicle_id,
        message=f"Trip {trip.id} is fully loaded and ready for departure",
    )

    return TripResponse.model_validate(trip)
