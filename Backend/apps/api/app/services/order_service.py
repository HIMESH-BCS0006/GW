"""
Order Service – order lifecycle, derivation, cutoff rollover, and idempotency.
"""

from datetime import date, datetime, time, timedelta
import uuid
from typing import Dict, List, Optional, Tuple
from sqlalchemy.orm import Session

from app.core.clock import business_now
from app.core.errors import (
    AppException,
    ValidationException,
    ForbiddenScopeException,
    InvalidTransitionException,
    NotOperatingDayException,
)
from app.models.domain import (
    CalendarDay,
    Deferral,
    Order,
    Outlet,
    OutletServiceState,
    Receipt,
    SyncOp,
    Trip,
    TripStop,
    User,
)
from app.schemas.field import (
    RecordReceiptRequest,
    ReceiptResponse,
)
from app.schemas.order import (
    CreateOrderRequest,
    CreateOrderResponse,
    OrderResponse,
    CancelOrderRequest,
    DeferOrderRequest,
    DeferralResponse,
)
from app.services.notification_service import emit_event

# Default unit constants per brand and temp requirement
DEFAULT_UNIT_CONSTANTS = {
    ("Fresh", "ambient"): {"kg_per_unit": 2.5, "m3_per_unit": 0.012},
    ("Fresh", "chilled"): {"kg_per_unit": 3.0, "m3_per_unit": 0.015},
    ("Style", "ambient"): {"kg_per_unit": 1.5, "m3_per_unit": 0.025},
    ("Tech", "ambient"): {"kg_per_unit": 15.0, "m3_per_unit": 0.080},
}


def derive_order_weight_and_volume(
    brand: str,
    temp_requirement: str,
    order_units: int,
    order_weight_kg: Optional[float] = None,
    order_volume_m3: Optional[float] = None,
) -> Tuple[float, float]:
    """
    Derives kg and m3 if omitted, using per-brand, per-temp constants (D18).
    """
    if order_weight_kg is not None and order_volume_m3 is not None:
        return float(order_weight_kg), float(order_volume_m3)

    key = (brand, temp_requirement)
    constants = DEFAULT_UNIT_CONSTANTS.get(key) or DEFAULT_UNIT_CONSTANTS.get((brand, "ambient"))
    if not constants:
        raise ValidationException(f"No unit constants configured for brand {brand} and temp {temp_requirement}")

    derived_kg = order_weight_kg if order_weight_kg is not None else round(order_units * constants["kg_per_unit"], 2)
    derived_m3 = order_volume_m3 if order_volume_m3 is not None else round(order_units * constants["m3_per_unit"], 3)
    return float(derived_kg), float(derived_m3)


def get_next_operating_date(db: Session, after_date: date) -> Optional[date]:
    """Finds the next operating calendar day strictly after after_date."""
    cal = (
        db.query(CalendarDay)
        .filter(CalendarDay.date > after_date, CalendarDay.is_operating == True)
        .order_by(CalendarDay.date.asc())
        .first()
    )
    return cal.date if cal else None


def resolve_delivery_date(
    db: Session,
    requested_date: Optional[date],
    now_dt: datetime,
) -> Tuple[date, bool, Optional[date]]:
    """
    Resolves final delivery date under 16:00 cutoff rule (D18).
    Returns (delivery_date, rolled_over, requested_delivery_date).
    """
    cutoff_time = time(16, 0)
    current_date = now_dt.date()

    if requested_date is not None:
        # Check if requested date is a valid operating day
        cal_req = db.query(CalendarDay).filter_by(date=requested_date).first()
        if not cal_req or not cal_req.is_operating or requested_date < current_date:
            raise NotOperatingDayException(f"Date {requested_date} is not an open operating day")

        # Cutoff is 16:00 on requested_date - 1 day
        cutoff_dt = datetime.combine(requested_date - timedelta(days=1), cutoff_time, tzinfo=now_dt.tzinfo)
        if now_dt >= cutoff_dt or requested_date <= current_date:
            # Cutoff passed -> roll over to next open operating day
            next_op = get_next_operating_date(db, max(current_date, requested_date))
            if not next_op:
                raise NotOperatingDayException("No future operating date available in calendar")
            return next_op, True, requested_date
        else:
            return requested_date, False, None
    else:
        # Omitted date -> find earliest operating day whose cutoff has not passed
        future_days = (
            db.query(CalendarDay)
            .filter(CalendarDay.date >= current_date, CalendarDay.is_operating == True)
            .order_by(CalendarDay.date.asc())
            .all()
        )
        for c in future_days:
            cutoff_dt = datetime.combine(c.date - timedelta(days=1), cutoff_time, tzinfo=now_dt.tzinfo)
            if now_dt < cutoff_dt and c.date > current_date:
                return c.date, False, None

        # Fallback to next operating day if none found
        next_op = get_next_operating_date(db, current_date)
        if not next_op:
            raise NotOperatingDayException("No open operating day found in calendar")
        return next_op, False, None


def enrich_order_response(order: Order, db: Session) -> OrderResponse:
    """Enriches an Order with trip_id, stop_id, eta if planned."""
    stop = db.query(TripStop).filter_by(order_id=order.id).first()
    trip_id = stop.trip_id if stop else None
    stop_id = stop.id if stop else None
    eta = stop.eta if stop else None

    receipt_status = stop.receipt_status if stop else None

    return OrderResponse(
        id=order.id,
        outlet_id=order.outlet_id,
        delivery_date=order.delivery_date,
        requested_delivery_date=order.requested_delivery_date,
        placed_at=order.placed_at,
        status=order.status,
        temp_requirement=order.temp_requirement,
        order_units=order.order_units,
        order_weight_kg=order.order_weight_kg,
        order_volume_m3=order.order_volume_m3,
        rolled_over=order.rolled_over,
        deferral_count=order.deferral_count,
        cancel_reason=order.cancel_reason,
        trip_id=trip_id,
        stop_id=stop_id,
        eta=eta,
        receipt_status=receipt_status,
        note=order.note,
        client_op_id=order.client_op_id,
    )


def create_order(db: Session, req: CreateOrderRequest, user_id: str) -> CreateOrderResponse:
    now_dt = business_now()

    # 1. Validate Outlet exists
    outlet = db.query(Outlet).filter_by(id=req.outlet_id).first()
    if not outlet:
        raise ValidationException(f"Unknown outlet ID: {req.outlet_id}")

    # 2. Validate Temperature (D9: Chilled only for Fresh)
    if req.temp_requirement == "chilled" and outlet.brand != "Fresh":
        raise ValidationException("Chilled temperature requirement is only allowed for Fresh brand outlets")

    # 3. Derive weight and volume
    weight_kg, volume_m3 = derive_order_weight_and_volume(
        brand=outlet.brand,
        temp_requirement=req.temp_requirement,
        order_units=req.order_units,
        order_weight_kg=req.order_weight_kg,
        order_volume_m3=req.order_volume_m3,
    )

    # 4. Resolve delivery date under cutoff rule
    delivery_date, rolled_over, requested_delivery_date = resolve_delivery_date(
        db, req.delivery_date, now_dt
    )

    # 5. Handle idempotency via client_op_id
    if req.client_op_id:
        existing_op = db.query(SyncOp).filter_by(client_op_id=req.client_op_id).first()
        if existing_op and existing_op.result in ("applied", "replayed"):
            # Return existing order
            existing_order = db.query(Order).filter_by(client_op_id=req.client_op_id).first()
            if existing_order:
                return CreateOrderResponse(
                    order=enrich_order_response(existing_order, db),
                    confirmation_code=f"WP-CONF-{existing_order.id[-6:]}",
                    rolled_over=existing_order.rolled_over,
                    requested_delivery_date=existing_order.requested_delivery_date,
                )

    # 6. Create Order
    order_id = f"ORD-{uuid.uuid4().hex[:10].upper()}"
    confirmation_code = f"WP-CONF-{order_id[-6:]}"

    order = Order(
        id=order_id,
        outlet_id=req.outlet_id,
        delivery_date=delivery_date,
        requested_delivery_date=requested_delivery_date,
        placed_at=now_dt,
        status="SUBMITTED",
        temp_requirement=req.temp_requirement,
        order_units=req.order_units,
        order_weight_kg=weight_kg,
        order_volume_m3=volume_m3,
        rolled_over=rolled_over,
        deferral_count=0,
        note=req.note,
        client_op_id=req.client_op_id,
    )
    db.add(order)

    # Record sync op if client_op_id was provided
    if req.client_op_id:
        db_user = db.query(User).filter((User.id == user_id) | (User.username == user_id)).first()
        valid_user_id = db_user.id if db_user else user_id
        db.add(SyncOp(
            client_op_id=req.client_op_id,
            device_id="web",
            client_seq=1,
            user_id=valid_user_id,
            op_type="create_order",
            payload={"order_id": order_id},
            client_ts=now_dt,
            received_at=now_dt,
            applied_at=now_dt,
            result="applied",
            reason=None,
        ))

    db.commit()
    db.refresh(order)

    # Emit event and notification
    emit_event(
        db=db,
        event_type="order.submitted",
        payload={"order_id": order.id, "outlet_id": order.outlet_id, "delivery_date": str(order.delivery_date)},
        audience_role="store_manager",
        audience_scope=order.outlet_id,
        notification_message=f"Order {order.id} submitted for {order.delivery_date}",
    )
    db.commit()

    return CreateOrderResponse(
        order=enrich_order_response(order, db),
        confirmation_code=confirmation_code,
        rolled_over=rolled_over,
        requested_delivery_date=requested_delivery_date,
    )


def list_orders(db: Session, outlet_id: Optional[str] = None) -> List[OrderResponse]:
    query = db.query(Order)
    if outlet_id:
        query = query.filter(Order.outlet_id == outlet_id)
    orders = query.order_by(Order.placed_at.desc()).all()
    return [enrich_order_response(o, db) for o in orders]


def get_order_by_id(db: Session, order_id: str, outlet_id: Optional[str] = None) -> OrderResponse:
    query = db.query(Order).filter_by(id=order_id)
    if outlet_id:
        query = query.filter_by(outlet_id=outlet_id)
    order = query.first()
    if not order:
        raise AppException(code="ORDER_NOT_FOUND", message=f"Order {order_id} not found", status_code=404)
    return enrich_order_response(order, db)


def cancel_order(db: Session, order_id: str, req: CancelOrderRequest, outlet_id: Optional[str] = None) -> OrderResponse:
    query = db.query(Order).filter_by(id=order_id)
    if outlet_id:
        query = query.filter_by(outlet_id=outlet_id)
    order = query.first()
    if not order:
        raise AppException(code="ORDER_NOT_FOUND", message=f"Order {order_id} not found", status_code=404)

    if order.status not in ("SUBMITTED", "PLANNED", "SCHEDULED", "DEFERRED"):
        raise InvalidTransitionException(f"Cannot cancel order in state {order.status}")

    # Remove from trip stop if planned/scheduled
    stop = db.query(TripStop).filter_by(order_id=order.id).first()
    if stop:
        db.delete(stop)

    # Clean up deferral record if deferred
    db.query(Deferral).filter_by(order_id=order.id).delete()

    order.status = "CANCELLED"
    order.cancel_reason = req.reason
    if req.note:
        order.note = f"{order.note or ''}\nCancel Note: {req.note}".strip()
    db.commit()
    db.refresh(order)

    notif_msg = f"Order {order.id} cancelled: {req.reason}"
    if req.note:
        notif_msg += f" - Note: {req.note}"

    emit_event(
        db=db,
        event_type="order.cancelled",
        payload={"order_id": order.id, "reason": req.reason, "note": req.note},
        audience_role="store_manager",
        audience_scope=order.outlet_id,
        notification_message=notif_msg,
    )
    db.commit()

    return enrich_order_response(order, db)


def defer_order_manually(db: Session, order_id: str, req: DeferOrderRequest, user_id: str) -> DeferralResponse:
    order = db.query(Order).filter_by(id=order_id).first()
    if not order:
        raise AppException(code="ORDER_NOT_FOUND", message=f"Order {order_id} not found", status_code=404)

    if order.status not in ("SUBMITTED", "PLANNED", "SCHEDULED"):
        raise InvalidTransitionException(f"Cannot defer order in state {order.status}")

    # Remove from trip stop if attached
    stop = db.query(TripStop).filter_by(order_id=order.id).first()
    if stop:
        db.delete(stop)

    now = business_now()
    deferral_id = f"DEF-{uuid.uuid4().hex[:10].upper()}"

    deferral = Deferral(
        id=deferral_id,
        order_id=order.id,
        from_delivery_date=order.delivery_date,
        reason_code=req.reason_code or "MANUAL",
        reason_class="DISPATCHER",
        reason_text=req.reason_text,
        consequence_text=f"Deferred by dispatcher {user_id}. {req.note or ''}".strip(),
        details_json={"note": req.note},
        decided_by="dispatcher",
        decided_by_user=user_id,
        decided_at=now,
        notified_at=now,
    )
    db.add(deferral)

    order.status = "DEFERRED"
    order.deferral_count += 1

    # Update outlet service state
    st = db.query(OutletServiceState).filter_by(outlet_id=order.outlet_id).first()
    if st:
        st.last_deferred_date = order.delivery_date
        st.consecutive_deferrals += 1
    else:
        db.add(OutletServiceState(
            outlet_id=order.outlet_id,
            last_deferred_date=order.delivery_date,
            consecutive_deferrals=1,
        ))

    db.commit()
    db.refresh(deferral)

    emit_event(
        db=db,
        event_type="order.deferred",
        payload={"order_id": order.id, "reason": req.reason_text},
        audience_role="store_manager",
        audience_scope=order.outlet_id,
        notification_message=f"Order {order.id} was deferred: {req.reason_text}",
    )
    db.commit()

    return DeferralResponse.model_validate(deferral)


def requeue_order(db: Session, order_id: str) -> OrderResponse:
    order = db.query(Order).filter_by(id=order_id).first()
    if not order:
        raise AppException(code="ORDER_NOT_FOUND", message=f"Order {order_id} not found", status_code=404)

    if order.status not in ("DEFERRED", "SUBMITTED"):
        raise InvalidTransitionException(f"Cannot requeue order in status {order.status}; must be DEFERRED")

    now = business_now()
    order.status = "SUBMITTED"

    # Mark the latest deferral record resolved
    latest_def = (
        db.query(Deferral)
        .filter_by(order_id=order.id)
        .order_by(Deferral.decided_at.desc())
        .first()
    )
    if latest_def:
        latest_def.resolved_at = now
        latest_def.resolved_to_date = order.delivery_date

    db.commit()
    db.refresh(order)

    emit_event(
        db=db,
        event_type="order.requeued",
        payload={"order_id": order.id, "outlet_id": order.outlet_id, "delivery_date": str(order.delivery_date)},
        audience_role="dispatcher",
        audience_scope=None,
        notification_message=f"Order {order.id} was re-queued for next plan generation",
    )
    db.commit()

    return enrich_order_response(order, db)


def batch_requeue_orders(db: Session, order_ids: List[str]) -> List[OrderResponse]:
    results = []
    now = business_now()
    for order_id in order_ids:
        order = db.query(Order).filter_by(id=order_id).first()
        if order and order.status in ("DEFERRED", "SUBMITTED"):
            order.status = "SUBMITTED"
            latest_def = (
                db.query(Deferral)
                .filter_by(order_id=order.id)
                .order_by(Deferral.decided_at.desc())
                .first()
            )
            if latest_def:
                latest_def.resolved_at = now
                latest_def.resolved_to_date = order.delivery_date
            db.flush()
            results.append(enrich_order_response(order, db))

    db.commit()

    if results:
        emit_event(
            db=db,
            event_type="order.requeued",
            payload={"count": len(results), "order_ids": [r.id for r in results]},
            audience_role="dispatcher",
            audience_scope=None,
            notification_message=f"{len(results)} orders re-queued for next plan generation",
        )
        db.commit()

    return results



def get_outlet_expected_deliveries(db: Session, outlet_id: str) -> List[TripStop]:
    """Returns trip stops for orders belonging to this outlet that are not cancelled."""
    stops = (
        db.query(TripStop)
        .join(Order, TripStop.order_id == Order.id)
        .filter(Order.outlet_id == outlet_id, Order.status.in_(["PLANNED", "SCHEDULED", "LOADED", "IN_TRANSIT", "DELIVERED"]))
        .order_by(TripStop.seq.asc())
        .all()
    )
    return stops


def record_stop_receipt_service(
    db: Session,
    stop_id: str,
    req: RecordReceiptRequest,
    user_id: str,
    user_outlet_id: Optional[str] = None,
    user_role: str = "store_manager",
) -> ReceiptResponse:
    stop = db.query(TripStop).filter_by(id=stop_id).first()
    if not stop:
        stop = db.query(TripStop).filter_by(order_id=stop_id).first()
    if not stop:
        raise AppException(code="STOP_NOT_FOUND", message=f"Stop {stop_id} not found", status_code=404)

    order = db.query(Order).filter_by(id=stop.order_id).first()
    if user_role == "store_manager" and user_outlet_id and order and order.outlet_id != user_outlet_id:
        raise ForbiddenScopeException(f"Store manager of outlet '{user_outlet_id}' cannot confirm receipt for outlet '{order.outlet_id}'")

    now_dt = business_now()
    receipt_id = f"REC-{uuid.uuid4().hex[:8].upper()}"
    rcp = Receipt(
        id=receipt_id,
        stop_id=stop.id,
        outcome=req.outcome,
        note=req.note,
        confirmed_by=user_id,
        confirmed_at=now_dt,
    )
    db.add(rcp)
    stop.receipt_status = "CONFIRMED" if req.outcome == "full" else "DISCREPANCY"
    stop.status = "DELIVERED" if req.outcome == "full" else "PARTIAL"
    stop.outcome = "delivered" if req.outcome == "full" else "partial"
    stop.completed_at = now_dt

    if order:
        order.status = "DELIVERED" if req.outcome == "full" else "PARTIALLY_DELIVERED"
        st = db.query(OutletServiceState).filter_by(outlet_id=order.outlet_id).first()
        if not st:
            st = OutletServiceState(
                outlet_id=order.outlet_id,
                last_served_date=now_dt.date(),
                consecutive_deferrals=0,
            )
            db.add(st)
        else:
            st.last_served_date = now_dt.date()
            st.consecutive_deferrals = 0

    trip = db.query(Trip).filter_by(id=stop.trip_id).first()
    if trip:
        all_stops = db.query(TripStop).filter_by(trip_id=trip.id).all()
        all_done = all(
            s.status in ["DELIVERED", "PARTIAL", "FAILED", "SKIPPED"]
            or s.receipt_status in ["CONFIRMED", "DISCREPANCY"]
            or s.id == stop.id
            for s in all_stops
        )
        if all_done:
            trip.status = "COMPLETED"

    if req.client_op_id:
        db_user = db.query(User).filter((User.id == user_id) | (User.username == user_id)).first()
        valid_user_id = db_user.id if db_user else user_id
        db.add(SyncOp(
            client_op_id=req.client_op_id,
            device_id="store_web",
            client_seq=1,
            user_id=valid_user_id,
            op_type="record_receipt",
            payload={"stop_id": stop.id, "outcome": req.outcome},
            client_ts=now_dt,
            received_at=now_dt,
            applied_at=now_dt,
            result="applied",
            reason=None,
        ))

    db.commit()
    db.refresh(rcp)

    # Emit events to dispatcher, driver, and store manager
    emit_event(
        db,
        event_type="receipt.confirmed",
        payload={
            "receipt_id": rcp.id,
            "stop_id": stop.id,
            "order_id": stop.order_id,
            "trip_id": stop.trip_id,
            "outcome": req.outcome,
        },
        audience_role="dispatcher",
        audience_scope=trip.depot_id if trip else None,
        notification_message=f"Receipt confirmed ({req.outcome}) for order {stop.order_id}",
    )
    if order:
        emit_event(
            db,
            event_type="order.delivered",
            payload={
                "order_id": order.id,
                "stop_id": stop.id,
                "trip_id": stop.trip_id,
                "status": order.status,
            },
            audience_role="store_manager",
            audience_scope=order.outlet_id,
            notification_message=f"Order {order.id} has been delivered and confirmed.",
        )
    emit_event(
        db,
        event_type="receipt.confirmed",
        payload={
            "receipt_id": rcp.id,
            "stop_id": stop.id,
            "order_id": stop.order_id,
            "outcome": req.outcome,
        },
        audience_role="driver",
        audience_scope=trip.vehicle_id if trip else None,
        notification_message=f"Receipt confirmed by store manager for stop {stop.id}",
    )
    if trip and trip.status == "COMPLETED":
        emit_event(
            db,
            event_type="trip.completed",
            payload={"trip_id": trip.id, "vehicle_id": trip.vehicle_id, "depot_id": trip.depot_id},
            audience_role="dispatcher",
            audience_scope=trip.depot_id,
            notification_message=f"Trip {trip.id} completed: all deliveries finished.",
        )
        emit_event(
            db,
            event_type="trip.completed",
            payload={"trip_id": trip.id, "vehicle_id": trip.vehicle_id},
            audience_role="driver",
            audience_scope=trip.vehicle_id,
            notification_message=f"Trip {trip.id} completed. Return to depot.",
        )
    db.commit()

    return ReceiptResponse.model_validate(rcp)

