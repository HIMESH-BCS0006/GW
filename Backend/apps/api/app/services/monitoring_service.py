"""
Monitoring, Alerts, Deferrals, Load Checks and Exceptions Service.
Implements D14, D20, D21, D24, and real-time live monitoring.
"""

from datetime import datetime, timedelta, time
import uuid
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from app.core.clock import business_now
from app.core.config import settings
from app.core.errors import AppException, ValidationException
from app.models.domain import (
    Deferral,
    Event,
    ExceptionRecord,
    LoadCheck,
    Notification,
    Order,
    Outlet,
    OutletServiceState,
    SyncOp,
    Trip,
    TripStop,
    User,
    Vehicle,
)
from app.schemas.field import (
    AlertResponseItem,
    ExceptionDecisionRequest,
    ExceptionResponse,
    LiveMonitoringNextStop,
    LiveMonitoringResponse,
    LiveMonitoringStop,
    LiveMonitoringTrip,
    LoadCheckResponse,
)
from app.schemas.order import DeferralResponse
from app.services.notification_service import emit_event


DELAY_ALERT_MIN = 15


def get_live_monitoring_service(db: Session, depot_id: Optional[str] = None) -> LiveMonitoringResponse:
    now_dt = business_now()
    today = now_dt.date()

    query = db.query(Trip)
    if depot_id:
        query = query.filter_by(depot_id=depot_id)
    trips = query.order_by(Trip.trip_no.asc(), Trip.vehicle_id.asc()).all()

    outlets = {o.id: o for o in db.query(Outlet).all()}
    drivers = {u.vehicle_id: u.display_name for u in db.query(User).filter(User.vehicle_id.isnot(None)).all()}

    monitoring_trips: List[LiveMonitoringTrip] = []

    for t in trips:
        stops = db.query(TripStop).filter_by(trip_id=t.id).order_by(TripStop.seq.asc()).all()
        exceptions = db.query(ExceptionRecord).filter_by(trip_id=t.id, status="OPEN").all()
        open_exc_models = [ExceptionResponse.model_validate(e) for e in exceptions]

        stops_completed = 0
        live_stops: List[LiveMonitoringStop] = []
        next_stop_item: Optional[LiveMonitoringNextStop] = None
        max_delay = 0

        for s in stops:
            ord_rec = db.query(Order).filter_by(id=s.order_id).first()
            out = outlets.get(ord_rec.outlet_id) if ord_rec else None

            is_completed = s.status in ["DELIVERED", "PARTIAL", "FAILED", "SKIPPED"]
            if is_completed:
                stops_completed += 1

            pod_recorded = s.receipt_status in ["CONFIRMED", "DISCREPANCY"] or s.outcome is not None
            at_risk = any(e.stop_id == s.id or e.type == "vehicle_issue" for e in exceptions)

            # Compute delay if pending/arrived and ETA passed
            projected = s.eta
            if not is_completed and s.eta:
                try:
                    eta_parts = s.eta.split(":")
                    eta_time = time(int(eta_parts[0]), int(eta_parts[1]))
                    eta_dt = datetime.combine(today, eta_time)
                    if now_dt > eta_dt:
                        diff_min = int((now_dt - eta_dt).total_seconds() / 60)
                        if diff_min > max_delay:
                            max_delay = diff_min
                except Exception:
                    pass

            if not is_completed and next_stop_item is None and ord_rec:
                next_stop_item = LiveMonitoringNextStop(
                    outlet_id=ord_rec.outlet_id,
                    eta=s.eta,
                )

            live_stops.append(LiveMonitoringStop(
                id=s.id,
                outlet_id=ord_rec.outlet_id if ord_rec else "",
                status=s.status,
                eta=s.eta,
                pod_recorded=pod_recorded,
                projected_arrival=projected,
                window_close_time=out.window_close_time if out else "08:00",
                parking_constraint=out.parking_constraint if out else "normal",
                at_risk=at_risk,
                arrived_at=s.arrived_at,
                completed_at=s.completed_at,
            ))

        # Determine health status
        health = "on_schedule"
        if t.status == "BLOCKED" or len(exceptions) > 0:
            health = "blocked"
        elif max_delay >= DELAY_ALERT_MIN:
            health = "delayed"

        driver_name = drivers.get(t.vehicle_id, f"Driver ({t.vehicle_id})")

        monitoring_trips.append(LiveMonitoringTrip(
            vehicle_id=t.vehicle_id,
            driver_name=driver_name,
            trip_status=t.status,
            brand=t.brand,
            district=t.district,
            stops_completed=stops_completed,
            stops_total=len(stops),
            health=health,
            delay_min=max_delay if max_delay > 0 else None,
            next_stop=next_stop_item,
            open_exceptions=open_exc_models,
            stops=live_stops,
        ))

    return LiveMonitoringResponse(
        last_synced_at=now_dt,
        trips=monitoring_trips,
    )


def list_alerts_service(db: Session, depot_id: Optional[str] = None) -> List[AlertResponseItem]:
    now_dt = business_now()
    alerts: List[AlertResponseItem] = []

    # 1. Shortfall Alerts
    lc_query = db.query(LoadCheck).filter_by(status="OPEN")
    for lc in lc_query.all():
        alerts.append(AlertResponseItem(
            id=f"ALT-LC-{lc.id}",
            type="shortfall",
            severity="critical",
            status="open",
            entity_ref={"load_check_id": lc.id, "trip_id": lc.trip_id, "order_id": lc.order_id},
            message=f"Warehouse shortfall on trip {lc.trip_id}: {lc.issue} stock for order {lc.order_id}",
            created_at=now_dt,
        ))

    # 2. Open Exception Alerts
    exc_query = db.query(ExceptionRecord).filter_by(status="OPEN")
    for exc in exc_query.all():
        severity = "critical" if exc.type == "vehicle_issue" else "warning"
        alerts.append(AlertResponseItem(
            id=f"ALT-EXC-{exc.id}",
            type="exception",
            severity=severity,
            status="open",
            entity_ref={"exception_id": exc.id, "trip_id": exc.trip_id, "stop_id": exc.stop_id},
            message=f"Driver reported exception on trip {exc.trip_id}: {exc.type}" + (f" ({exc.note})" if exc.note else ""),
            created_at=exc.reported_at,
        ))

    # 3. Repeat Deferral Alerts (consecutive_deferrals >= 2)
    repeat_query = db.query(OutletServiceState).filter(OutletServiceState.consecutive_deferrals >= 2)
    for oss in repeat_query.all():
        alerts.append(AlertResponseItem(
            id=f"ALT-DEF-{oss.outlet_id}",
            type="repeat_deferral",
            severity="warning",
            status="open",
            entity_ref={"outlet_id": oss.outlet_id, "consecutive_deferrals": oss.consecutive_deferrals},
            message=f"Outlet {oss.outlet_id} has suffered {oss.consecutive_deferrals} consecutive deferrals",
            created_at=now_dt,
        ))

    # 4. Sync Conflict Alerts
    conflict_query = db.query(SyncOp).filter_by(result="applied_with_conflict").order_by(SyncOp.received_at.desc()).limit(10)
    for c in conflict_query.all():
        alerts.append(AlertResponseItem(
            id=f"ALT-SYNC-{c.client_op_id[:8]}",
            type="sync_conflict",
            severity="info",
            status="open",
            entity_ref={"client_op_id": c.client_op_id, "op_type": c.op_type, "device_id": c.device_id},
            message=f"Offline sync conflict on op {c.op_type}: {c.reason}",
            created_at=c.received_at,
        ))

    return alerts


def resolve_exception_decision_service(
    db: Session,
    exception_id: str,
    req: ExceptionDecisionRequest,
    user_id: str,
) -> ExceptionResponse:
    exc = db.query(ExceptionRecord).filter_by(id=exception_id).first()
    if not exc:
        raise AppException(code="EXCEPTION_NOT_FOUND", message=f"Exception {exception_id} not found", status_code=404)

    if exc.status == "DECIDED":
        return ExceptionResponse.model_validate(exc)

    now_dt = business_now()
    exc.status = "DECIDED"
    exc.decision = req.decision
    exc.decision_note = req.note
    exc.decided_by = user_id
    exc.decided_at = now_dt

    trip = db.query(Trip).filter_by(id=exc.trip_id).first()
    affected_stops = [exc.stop_id] if exc.stop_id else []

    if exc.type == "vehicle_issue" and trip:
        stops_to_update = (
            db.query(TripStop)
            .filter_by(trip_id=trip.id)
            .filter(TripStop.status.in_(["EXCEPTION", "PENDING", "ARRIVED"]))
            .all()
        )
        affected_stops = [s.id for s in stops_to_update]
    else:
        stops_to_update = db.query(TripStop).filter_by(id=exc.stop_id).all() if exc.stop_id else []

    if req.decision == "retry":
        for s in stops_to_update:
            s.status = "PENDING"

    elif req.decision == "skip":
        for s in stops_to_update:
            s.status = "SKIPPED"
            ord_obj = db.query(Order).filter_by(id=s.order_id).first()
            if ord_obj:
                ord_obj.status = "DEFERRED"
                ord_obj.deferral_count += 1
                def_id = f"DEF-{uuid.uuid4().hex[:8].upper()}"
                deferral = Deferral(
                    id=def_id,
                    order_id=ord_obj.id,
                    from_delivery_date=trip.delivery_date if trip else now_dt.date(),
                    reason_code="EXCEPTION_SKIPPED",
                    reason_class="DISPATCHER",
                    reason_text=f"Dispatcher skipped stop after {exc.type}" + (f": {req.note}" if req.note else ""),
                    consequence_text="Order skipped and deferred to next cycle",
                    decided_by="dispatcher",
                    decided_by_user=user_id,
                    decided_at=now_dt,
                )
                db.add(deferral)

                oss = db.query(OutletServiceState).filter_by(outlet_id=ord_obj.outlet_id).first()
                if not oss:
                    oss = OutletServiceState(outlet_id=ord_obj.outlet_id, last_deferred_date=trip.delivery_date if trip else now_dt.date(), consecutive_deferrals=1)
                    db.add(oss)
                else:
                    oss.last_deferred_date = trip.delivery_date if trip else now_dt.date()
                    oss.consecutive_deferrals += 1

    db.commit()
    db.refresh(exc)

    emit_event(
        db,
        event_type="exception.decided",
        payload={"exception_id": exc.id, "decision": req.decision, "trip_id": exc.trip_id},
        audience_role="driver",
        audience_scope=trip.vehicle_id if trip else None,
        message=f"Exception on trip {exc.trip_id} decided: {req.decision}",
    )

    resp = ExceptionResponse.model_validate(exc)
    resp.affected_stop_ids = affected_stops
    return resp


def list_load_checks_service(
    db: Session,
    status: Optional[str] = None,
    depot_id: Optional[str] = None,
) -> List[LoadCheckResponse]:
    query = db.query(LoadCheck)
    if status:
        query = query.filter_by(status=status)
    if depot_id:
        trips = db.query(Trip.id).filter_by(depot_id=depot_id).subquery()
        query = query.filter(LoadCheck.trip_id.in_(trips))
    checks = query.order_by(LoadCheck.id.desc()).all()
    return [LoadCheckResponse.model_validate(c) for c in checks]


def list_deferrals_service(db: Session, depot_id: Optional[str] = None) -> List[DeferralResponse]:
    query = db.query(Deferral)
    if depot_id:
        orders = (
            db.query(Order.id)
            .join(Outlet, Order.outlet_id == Outlet.id)
            .filter(Outlet.depot_id == depot_id)
            .subquery()
        )
        query = query.filter(Deferral.order_id.in_(orders))
    deferrals = query.order_by(Deferral.decided_at.desc()).all()

    order_ids = [d.order_id for d in deferrals]
    orders_map = {o.id: o for o in db.query(Order).filter(Order.id.in_(order_ids)).all()} if order_ids else {}
    outlet_ids = [o.outlet_id for o in orders_map.values()]
    outlets_map = {ot.id: ot for ot in db.query(Outlet).filter(Outlet.id.in_(outlet_ids)).all()} if outlet_ids else {}

    results = []
    for d in deferrals:
        resp = DeferralResponse.model_validate(d)
        ord_obj = orders_map.get(d.order_id)
        if ord_obj:
            resp.order_status = ord_obj.status
            resp.outlet_id = ord_obj.outlet_id
            resp.temp_requirement = ord_obj.temp_requirement
            resp.order_units = ord_obj.order_units
            resp.order_weight_kg = ord_obj.order_weight_kg
            resp.order_volume_m3 = ord_obj.order_volume_m3
            resp.deferral_count = ord_obj.deferral_count
            resp.is_requeued = (ord_obj.status == "SUBMITTED")

            ot = outlets_map.get(ord_obj.outlet_id)
            if ot:
                resp.brand = ot.brand
                resp.district = ot.district
        else:
            resp.order_status = "UNKNOWN"
            resp.is_requeued = False
        results.append(resp)

    return results


def get_outlet_skip_history_service(db: Session, outlet_id: str) -> List[DeferralResponse]:
    orders = db.query(Order.id).filter_by(outlet_id=outlet_id).subquery()
    deferrals = db.query(Deferral).filter(Deferral.order_id.in_(orders)).order_by(Deferral.decided_at.desc()).all()

    order_ids = [d.order_id for d in deferrals]
    orders_map = {o.id: o for o in db.query(Order).filter(Order.id.in_(order_ids)).all()} if order_ids else {}
    outlet = db.query(Outlet).filter_by(id=outlet_id).first()

    results = []
    for d in deferrals:
        resp = DeferralResponse.model_validate(d)
        ord_obj = orders_map.get(d.order_id)
        if ord_obj:
            resp.order_status = ord_obj.status
            resp.outlet_id = ord_obj.outlet_id
            resp.temp_requirement = ord_obj.temp_requirement
            resp.order_units = ord_obj.order_units
            resp.order_weight_kg = ord_obj.order_weight_kg
            resp.order_volume_m3 = ord_obj.order_volume_m3
            resp.deferral_count = ord_obj.deferral_count
            resp.is_requeued = (ord_obj.status == "SUBMITTED")
        if outlet:
            resp.brand = outlet.brand
            resp.district = outlet.district
        results.append(resp)

    return results

