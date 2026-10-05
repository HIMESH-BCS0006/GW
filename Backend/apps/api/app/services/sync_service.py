"""
Offline Sync Service - Implements D14 offline conflict resolution, monotonic (device_id, client_seq)
replay, idempotency via sync_ops, and conflict alerting.
"""

from datetime import datetime
import uuid
from typing import Any, Dict, List
from sqlalchemy.orm import Session

from app.core.clock import business_now
from app.models.domain import (
    Event,
    Notification,
    Order,
    Receipt,
    SyncOp,
    Trip,
    TripStop,
    User,
)
from app.schemas.field import (
    CreateLoadCheckRequest,
    RecordReceiptRequest,
    RecordStopExceptionRequest,
    RecordStopOutcomeRequest,
    StartTripRequest,
    SyncBatchRequest,
    SyncBatchResponse,
    SyncOperationItem,
    SyncOperationResultItem,
)
from app.services.driver_service import (
    complete_trip_service,
    record_stop_arrival_service,
    record_stop_outcome_service,
    report_stop_exception_service,
    start_trip_service,
)
from app.services.loader_service import report_load_check_service
from app.services.notification_service import emit_event


def sync_offline_operations_service(
    db: Session,
    req: SyncBatchRequest,
    user_id: str,
    user_vehicle_id: str = None,
    user_role: str = "driver",
) -> SyncBatchResponse:
    # 1. Sort batch deterministically by (device_id, client_seq)
    sorted_ops = sorted(req.operations, key=lambda op: (op.device_id, op.client_seq))
    results: List[SyncOperationResultItem] = []

    now_dt = business_now()

    for op in sorted_ops:
        # 2. Check Idempotency
        existing = db.query(SyncOp).filter_by(client_op_id=op.client_op_id).first()
        if existing:
            results.append(SyncOperationResultItem(
                client_op_id=op.client_op_id,
                result="replayed",
                reason=f"Op previously processed with result '{existing.result}'",
            ))
            continue

        result_status = "applied"
        reason_msg = None

        try:
            # 3. Process Operation by type
            if op.op_type in ["start_trip", "startTrip"]:
                trip_id = op.payload.get("trip_id")
                plan_version = op.payload.get("plan_version", 1)
                trip = db.query(Trip).filter_by(id=trip_id).first() if trip_id else None

                # Server-authority command: rejected if cancelled, blocked, or plan_version is stale
                if not trip:
                    result_status = "rejected"
                    reason_msg = f"Trip '{trip_id}' not found"
                elif trip.status in ["CANCELLED", "BLOCKED"]:
                    result_status = "rejected"
                    reason_msg = f"Trip is {trip.status}"
                elif trip.plan_version != plan_version:
                    result_status = "rejected"
                    reason_msg = f"Stale plan_version ({plan_version} vs {trip.plan_version})"
                else:
                    start_trip_service(
                        db,
                        trip_id=trip_id,
                        req=StartTripRequest(plan_version=plan_version, client_op_id=op.client_op_id),
                        user_vehicle_id=user_vehicle_id,
                        user_role=user_role,
                    )
                    result_status = "applied"

            elif op.op_type in ["arrive_stop", "arriveStop", "recordStopArrival"]:
                stop_id = op.payload.get("stop_id")
                stop = db.query(TripStop).filter_by(id=stop_id).first() if stop_id else None
                trip = db.query(Trip).filter_by(id=stop.trip_id).first() if stop else None

                if not stop or not trip or trip.status == "CANCELLED":
                    # Field fact: NEVER rejected -> applied_with_conflict
                    result_status = "applied_with_conflict"
                    reason_msg = "Stop arrived offline but trip was modified or cancelled on server"
                    emit_event(
                        db,
                        event_type="sync.conflict",
                        payload={"client_op_id": op.client_op_id, "op_type": op.op_type, "stop_id": stop_id},
                        audience_role="dispatcher",
                        audience_scope=trip.depot_id if trip else None,
                        message=f"Sync conflict: Arrival recorded offline for cancelled/modified stop {stop_id}",
                    )
                else:
                    record_stop_arrival_service(db, stop_id=stop_id, user_vehicle_id=user_vehicle_id, user_role=user_role)
                    result_status = "applied"

            elif op.op_type in ["record_outcome", "recordOutcome", "recordStopOutcome"]:
                stop_id = op.payload.get("stop_id")
                outcome = op.payload.get("outcome", "delivered")
                quantity_delivered = op.payload.get("quantity_delivered")
                received_by = op.payload.get("received_by")
                outcome_note = op.payload.get("outcome_note")
                completed_at_raw = op.payload.get("completed_at")
                completed_at = datetime.fromisoformat(completed_at_raw) if completed_at_raw else op.client_ts

                stop = db.query(TripStop).filter_by(id=stop_id).first() if stop_id else None
                trip = db.query(Trip).filter_by(id=stop.trip_id).first() if stop else None

                if not stop or not trip or trip.status == "CANCELLED":
                    # Field fact: NEVER rejected -> applied_with_conflict
                    result_status = "applied_with_conflict"
                    reason_msg = "Delivery outcome recorded offline but stop was removed or trip was cancelled"
                    emit_event(
                        db,
                        event_type="sync.conflict",
                        payload={"client_op_id": op.client_op_id, "op_type": op.op_type, "stop_id": stop_id, "outcome": outcome},
                        audience_role="dispatcher",
                        audience_scope=trip.depot_id if trip else None,
                        message=f"Sync conflict: Delivery outcome recorded offline for modified/cancelled stop {stop_id}",
                    )
                else:
                    record_stop_outcome_service(
                        db,
                        stop_id=stop_id,
                        req=RecordStopOutcomeRequest(
                            outcome=outcome,
                            quantity_delivered=quantity_delivered,
                            received_by=received_by,
                            outcome_note=outcome_note,
                            completed_at=completed_at,
                            client_op_id=op.client_op_id,
                        ),
                        user_vehicle_id=user_vehicle_id,
                        user_role=user_role,
                    )
                    result_status = "applied"

            elif op.op_type in ["report_exception", "reportException", "reportStopException"]:
                stop_id = op.payload.get("stop_id")
                exc_type = op.payload.get("type", "other")
                note = op.payload.get("note")

                stop = db.query(TripStop).filter_by(id=stop_id).first() if stop_id else None
                trip = db.query(Trip).filter_by(id=stop.trip_id).first() if stop else None

                if not stop or not trip or trip.status == "CANCELLED":
                    result_status = "applied_with_conflict"
                    reason_msg = "Exception recorded offline for modified/cancelled stop"
                    emit_event(
                        db,
                        event_type="sync.conflict",
                        payload={"client_op_id": op.client_op_id, "op_type": op.op_type, "stop_id": stop_id},
                        audience_role="dispatcher",
                        audience_scope=None,
                        message=f"Sync conflict: Exception recorded offline for modified stop {stop_id}",
                    )
                else:
                    report_stop_exception_service(
                        db,
                        stop_id=stop_id,
                        req=RecordStopExceptionRequest(
                            type=exc_type,
                            note=note,
                            client_op_id=op.client_op_id,
                            client_seq=op.client_seq,
                            client_ts=op.client_ts,
                        ),
                        user_vehicle_id=user_vehicle_id,
                        user_role=user_role,
                    )
                    result_status = "applied"

            elif op.op_type in ["record_receipt", "recordReceipt", "recordStopReceipt"]:
                stop_id = op.payload.get("stop_id")
                outcome = op.payload.get("outcome", "full")
                note = op.payload.get("note")

                stop = db.query(TripStop).filter_by(id=stop_id).first() if stop_id else None
                if not stop:
                    result_status = "applied_with_conflict"
                    reason_msg = "Receipt recorded offline for missing stop"
                else:
                    receipt_id = f"REC-{uuid.uuid4().hex[:8].upper()}"
                    rcp = Receipt(
                        id=receipt_id,
                        stop_id=stop.id,
                        outcome=outcome,
                        note=note,
                        confirmed_by=user_id,
                        confirmed_at=op.client_ts or now_dt,
                    )
                    db.add(rcp)
                    stop.receipt_status = "CONFIRMED" if outcome == "full" else "DISCREPANCY"
                    db.commit()
                    result_status = "applied"

            elif op.op_type in ["complete_trip", "completeTrip"]:
                trip_id = op.payload.get("trip_id")
                trip = db.query(Trip).filter_by(id=trip_id).first() if trip_id else None
                if not trip:
                    result_status = "rejected"
                    reason_msg = "Trip not found"
                else:
                    complete_trip_service(db, trip_id=trip_id, user_vehicle_id=user_vehicle_id, user_role=user_role)
                    result_status = "applied"

            else:
                result_status = "rejected"
                reason_msg = f"Unknown op_type: '{op.op_type}'"

        except Exception as e:
            db.rollback()
            result_status = "rejected"
            reason_msg = str(e)

        # 4. Save SyncOp record
        db_user = db.query(User).filter((User.id == user_id) | (User.username == user_id)).first()
        valid_user_id = db_user.id if db_user else user_id
        sync_record = SyncOp(
            client_op_id=op.client_op_id,
            device_id=op.device_id,
            client_seq=op.client_seq,
            user_id=valid_user_id,
            op_type=op.op_type,
            payload=op.payload,
            client_ts=op.client_ts,
            received_at=now_dt,
            applied_at=now_dt if result_status in ["applied", "applied_with_conflict"] else None,
            result=result_status,
            reason=reason_msg,
        )
        db.add(sync_record)
        db.commit()

        results.append(SyncOperationResultItem(
            client_op_id=op.client_op_id,
            result=result_status,
            reason=reason_msg,
        ))

    return SyncBatchResponse(results=results)
