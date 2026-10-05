"""
Driver Service - Handles driver trip inspection, departure start, arrival, outcome reporting (D20),
field exceptions, trip completion, and vehicle scoping per D24.
"""

from datetime import datetime
import uuid
from typing import List, Optional
from sqlalchemy.orm import Session

from app.core.clock import business_now
from app.core.errors import (
    AppException,
    ForbiddenScopeException,
    InvalidTransitionException,
    ValidationException,
)
from app.models.domain import (
    Deferral,
    ExceptionRecord,
    Order,
    OutletServiceState,
    Trip,
    TripStop,
    Vehicle,
)
from app.schemas.field import (
    ExceptionResponse,
    RecordStopExceptionRequest,
    RecordStopOutcomeRequest,
    StartTripRequest,
)
from app.schemas.planning import (
    TripCard,
    TripResponse,
    TripStopResponse,
)
from app.services.loader_service import build_trip_card
from app.services.notification_service import emit_event


def get_driver_trips_service(db: Session, vehicle_id: str) -> List[TripCard]:
    if not vehicle_id:
        raise ForbiddenScopeException("User has no assigned vehicle")

    trips = (
        db.query(Trip)
        .filter_by(vehicle_id=vehicle_id)
        .order_by(Trip.delivery_date.desc(), Trip.trip_no.asc())
        .all()
    )
    return [build_trip_card(db, t) for t in trips]


def start_trip_service(
    db: Session,
    trip_id: str,
    req: StartTripRequest,
    user_vehicle_id: Optional[str] = None,
    user_role: str = "driver",
) -> TripResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    if user_role == "driver" and user_vehicle_id and trip.vehicle_id != user_vehicle_id:
        raise ForbiddenScopeException(f"Driver vehicle '{user_vehicle_id}' cannot start trip assigned to '{trip.vehicle_id}'")

    if trip.status in ["CANCELLED", "BLOCKED"]:
        raise InvalidTransitionException(f"Cannot start trip in status '{trip.status}'")

    if req.plan_version and trip.plan_version != req.plan_version:
        # Align with latest plan version if minor drift
        trip.plan_version = max(trip.plan_version, req.plan_version)

    if trip.status == "IN_PROGRESS":
        return TripResponse.model_validate(trip)

    trip.status = "IN_PROGRESS"
    # Transition orders to IN_TRANSIT
    stops = db.query(TripStop).filter_by(trip_id=trip.id).all()
    for s in stops:
        ord_obj = db.query(Order).filter_by(id=s.order_id).first()
        if ord_obj and ord_obj.status in ["LOADED", "SCHEDULED", "PLANNED"]:
            ord_obj.status = "IN_TRANSIT"

    db.commit()
    db.refresh(trip)

    emit_event(
        db,
        event_type="trip.started",
        payload={"trip_id": trip.id, "vehicle_id": trip.vehicle_id, "depot_id": trip.depot_id},
        audience_role="dispatcher",
        audience_scope=trip.depot_id,
        message=f"Driver started trip {trip.id} with vehicle {trip.vehicle_id}",
    )

    # Notify consignee store managers that order is on the way
    for s in stops:
        ord_obj = db.query(Order).filter_by(id=s.order_id).first()
        if ord_obj:
            emit_event(
                db,
                event_type="order.in_transit",
                payload={"order_id": ord_obj.id, "trip_id": trip.id, "status": "IN_TRANSIT"},
                audience_role="store_manager",
                audience_scope=ord_obj.outlet_id,
                notification_message=f"Order {ord_obj.id} is on the way for delivery",
            )
    db.commit()

    return TripResponse.model_validate(trip)



def record_stop_arrival_service(
    db: Session,
    stop_id: str,
    user_vehicle_id: Optional[str] = None,
    user_role: str = "driver",
) -> TripStopResponse:
    stop = db.query(TripStop).filter_by(id=stop_id).first()
    if not stop:
        raise AppException(code="STOP_NOT_FOUND", message=f"Stop {stop_id} not found", status_code=404)

    trip = db.query(Trip).filter_by(id=stop.trip_id).first()
    if user_role == "driver" and user_vehicle_id and trip and trip.vehicle_id != user_vehicle_id:
        raise ForbiddenScopeException(f"Driver vehicle '{user_vehicle_id}' cannot update stop for vehicle '{trip.vehicle_id}'")

    now_dt = business_now()
    stop.status = "ARRIVED"
    stop.arrived_at = now_dt
    db.commit()
    db.refresh(stop)

    emit_event(
        db,
        event_type="stop.arrived",
        payload={"stop_id": stop.id, "trip_id": stop.trip_id, "order_id": stop.order_id},
        audience_role="store_manager",
        audience_scope=None,
        message=f"Driver arrived at stop for order {stop.order_id}",
    )

    return TripStopResponse.model_validate(stop)


def record_stop_outcome_service(
    db: Session,
    stop_id: str,
    req: RecordStopOutcomeRequest,
    user_vehicle_id: Optional[str] = None,
    user_role: str = "driver",
) -> TripStopResponse:
    stop = db.query(TripStop).filter_by(id=stop_id).first()
    if not stop:
        raise AppException(code="STOP_NOT_FOUND", message=f"Stop {stop_id} not found", status_code=404)

    trip = db.query(Trip).filter_by(id=stop.trip_id).first()
    if user_role == "driver" and user_vehicle_id and trip and trip.vehicle_id != user_vehicle_id:
        raise ForbiddenScopeException(f"Driver vehicle '{user_vehicle_id}' cannot record outcome for vehicle '{trip.vehicle_id}'")

    order = db.query(Order).filter_by(id=stop.order_id).first()
    now_dt = business_now()
    completed_at = req.completed_at or now_dt

    stop.completed_at = completed_at
    stop.device_ts = completed_at
    stop.outcome = req.outcome
    stop.outcome_note = req.outcome_note
    stop.received_by = req.received_by

    if req.outcome == "delivered":
        stop.status = "DELIVERED"
        stop.quantity_delivered = order.order_units if order else req.quantity_delivered
        stop.receipt_status = "AWAITING"
        if order:
            order.status = "DELIVERED"
            oss = db.query(OutletServiceState).filter_by(outlet_id=order.outlet_id).first()
            if not oss:
                oss = OutletServiceState(outlet_id=order.outlet_id, last_served_date=trip.delivery_date if trip else now_dt.date(), consecutive_deferrals=0)
                db.add(oss)
            else:
                oss.last_served_date = trip.delivery_date if trip else now_dt.date()
                oss.consecutive_deferrals = 0

    elif req.outcome == "partial":
        stop.status = "PARTIAL"
        stop.quantity_delivered = req.quantity_delivered or (order.order_units // 2 if order else 1)
        stop.receipt_status = "AWAITING"
        if order:
            order.status = "PARTIALLY_DELIVERED"
            oss = db.query(OutletServiceState).filter_by(outlet_id=order.outlet_id).first()
            if not oss:
                oss = OutletServiceState(outlet_id=order.outlet_id, last_served_date=trip.delivery_date if trip else now_dt.date(), consecutive_deferrals=0)
                db.add(oss)
            else:
                oss.last_served_date = trip.delivery_date if trip else now_dt.date()
                oss.consecutive_deferrals = 0

    elif req.outcome in ["refused", "closed"]:
        stop.status = "FAILED"
        stop.quantity_delivered = 0
        stop.receipt_status = "NONE"
        if order:
            order.status = "DEFERRED"
            order.deferral_count += 1
            def_id = f"DEF-{uuid.uuid4().hex[:8].upper()}"
            deferral = Deferral(
                id=def_id,
                order_id=order.id,
                from_delivery_date=trip.delivery_date if trip else now_dt.date(),
                reason_code="DELIVERY_FAILED",
                reason_class="OPERATIONAL",
                reason_text=f"Delivery outcome: {req.outcome}" + (f" ({req.outcome_note})" if req.outcome_note else ""),
                consequence_text="Order failed and deferred to next cycle",
                decided_by="dispatcher",
                decided_at=now_dt,
            )
            db.add(deferral)

            oss = db.query(OutletServiceState).filter_by(outlet_id=order.outlet_id).first()
            if not oss:
                oss = OutletServiceState(outlet_id=order.outlet_id, last_deferred_date=trip.delivery_date if trip else now_dt.date(), consecutive_deferrals=1)
                db.add(oss)
            else:
                oss.last_deferred_date = trip.delivery_date if trip else now_dt.date()
                oss.consecutive_deferrals += 1

    db.commit()
    db.refresh(stop)

    emit_event(
        db,
        event_type=f"delivery.{req.outcome}",
        payload={
            "stop_id": stop.id,
            "trip_id": stop.trip_id,
            "order_id": stop.order_id,
            "outcome": req.outcome,
            "quantity_delivered": stop.quantity_delivered,
        },
        audience_role="store_manager" if req.outcome in ["delivered", "partial"] else "dispatcher",
        audience_scope=order.outlet_id if order else None,
        message=f"Delivery {req.outcome} for order {stop.order_id}",
    )

    return TripStopResponse.model_validate(stop)


def report_stop_exception_service(
    db: Session,
    stop_id: str,
    req: RecordStopExceptionRequest,
    user_vehicle_id: Optional[str] = None,
    user_role: str = "driver",
) -> ExceptionResponse:
    stop = db.query(TripStop).filter_by(id=stop_id).first()
    if not stop:
        raise AppException(code="STOP_NOT_FOUND", message=f"Stop {stop_id} not found", status_code=404)

    trip = db.query(Trip).filter_by(id=stop.trip_id).first()
    if user_role == "driver" and user_vehicle_id and trip and trip.vehicle_id != user_vehicle_id:
        raise ForbiddenScopeException(f"Driver vehicle '{user_vehicle_id}' cannot report exception for vehicle '{trip.vehicle_id}'")

    now_dt = business_now()
    exc_id = f"EXC-{uuid.uuid4().hex[:8].upper()}"

    affected_stops = [stop.id]
    if req.type == "vehicle_issue" and trip:
        # All pending or arrived stops on the trip are at risk
        other_stops = (
            db.query(TripStop)
            .filter_by(trip_id=trip.id)
            .filter(TripStop.status.in_(["PENDING", "ARRIVED"]))
            .all()
        )
        affected_stops = [s.id for s in other_stops]
        for s in other_stops:
            s.status = "EXCEPTION"
    else:
        stop.status = "EXCEPTION"

    exc = ExceptionRecord(
        id=exc_id,
        trip_id=trip.id if trip else stop.trip_id,
        stop_id=stop.id,
        type=req.type,
        note=req.note,
        reported_at=req.client_ts or now_dt,
        status="OPEN",
    )
    db.add(exc)
    db.commit()
    db.refresh(exc)

    emit_event(
        db,
        event_type="exception.reported",
        payload={
            "exception_id": exc.id,
            "trip_id": exc.trip_id,
            "stop_id": exc.stop_id,
            "type": exc.type,
            "affected_stops": affected_stops,
        },
        audience_role="dispatcher",
        audience_scope=trip.depot_id if trip else None,
        message=f"Field exception reported on trip {exc.trip_id}: {exc.type}",
    )

    resp = ExceptionResponse.model_validate(exc)
    resp.affected_stop_ids = affected_stops
    return resp


def complete_trip_service(
    db: Session,
    trip_id: str,
    user_vehicle_id: Optional[str] = None,
    user_role: str = "driver",
) -> TripResponse:
    trip = db.query(Trip).filter_by(id=trip_id).first()
    if not trip:
        raise AppException(code="TRIP_NOT_FOUND", message=f"Trip {trip_id} not found", status_code=404)

    if user_role == "driver" and user_vehicle_id and trip.vehicle_id != user_vehicle_id:
        raise ForbiddenScopeException(f"Driver vehicle '{user_vehicle_id}' cannot complete trip for vehicle '{trip.vehicle_id}'")

    trip.status = "COMPLETED"
    db.commit()
    db.refresh(trip)

    emit_event(
        db,
        event_type="trip.completed",
        payload={"trip_id": trip.id, "vehicle_id": trip.vehicle_id, "depot_id": trip.depot_id},
        audience_role="dispatcher",
        audience_scope=trip.depot_id,
        message=f"Trip {trip.id} completed by vehicle {trip.vehicle_id}",
    )

    return TripResponse.model_validate(trip)
