"""
Field roles, execution, monitoring, exceptions, receipts, and offline sync schemas.
Conforms to OpenAPI 3.1 contract and D14, D20, D21, D23, D24 decisions.
"""

from datetime import datetime
from typing import Any, Dict, List, Literal, Optional
from pydantic import BaseModel, ConfigDict, Field

from app.schemas.planning import StopDetail, TripCard, TripResponse, TripStopResponse


# ==============================================================================
# Loader Schemas
# ==============================================================================

class CreateLoadCheckRequest(BaseModel):
    order_id: str
    plan_version: int
    expected_qty: int
    loaded_qty: int
    issue: Literal["missing", "damaged"]
    note: Optional[str] = None
    client_op_id: Optional[str] = None


class ConfirmLoadRequest(BaseModel):
    plan_version: int


class LoadCheckResponse(BaseModel):
    id: str
    trip_id: str
    order_id: str
    plan_version: int
    expected_qty: int
    loaded_qty: int
    issue: str
    note: Optional[str] = None
    status: str
    resolution: Optional[str] = None
    reported_by: str
    resolved_by: Optional[str] = None
    vehicle_id: Optional[str] = None
    outlet_id: Optional[str] = None
    outlet_name: Optional[str] = None
    bay: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ResolveLoadCheckRequest(BaseModel):
    resolution: str
    note: Optional[str] = None


class LoadListResponse(BaseModel):
    plan_version: int
    trip: TripCard
    delivery_sequence: List[StopDetail]
    reverse_load_order: List[StopDetail]


# ==============================================================================
# Driver Schemas
# ==============================================================================

class StartTripRequest(BaseModel):
    plan_version: int
    client_op_id: Optional[str] = None


class RecordStopOutcomeRequest(BaseModel):
    outcome: Literal["delivered", "partial", "refused", "closed"]
    quantity_delivered: Optional[int] = None
    received_by: Optional[str] = None
    outcome_note: Optional[str] = None
    completed_at: datetime
    client_op_id: Optional[str] = None


class RecordStopExceptionRequest(BaseModel):
    type: Literal["dock_blocked", "outlet_closed", "vehicle_issue", "access_problem", "other"]
    note: Optional[str] = None
    client_op_id: Optional[str] = None
    client_seq: Optional[int] = None
    client_ts: Optional[datetime] = None
    plan_version: Optional[int] = None


class ExceptionResponse(BaseModel):
    id: str
    trip_id: str
    stop_id: Optional[str] = None
    affected_stop_ids: List[str] = []
    type: str
    note: Optional[str] = None
    reported_at: datetime
    status: str
    decision: Optional[str] = None
    decision_note: Optional[str] = None
    decided_by: Optional[str] = None
    decided_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ExceptionDecisionRequest(BaseModel):
    decision: Literal["retry", "skip"]
    note: Optional[str] = None
    override_reason: Optional[str] = None


# ==============================================================================
# Store Manager Receipts
# ==============================================================================

class RecordReceiptRequest(BaseModel):
    outcome: Literal["full", "discrepancy"]
    note: Optional[str] = None
    client_op_id: Optional[str] = None


class ReceiptResponse(BaseModel):
    id: str
    stop_id: str
    outcome: str
    note: Optional[str] = None
    confirmed_by: str
    confirmed_at: datetime
    qr_token: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# ==============================================================================
# Offline Sync Schemas
# ==============================================================================

class SyncOperationItem(BaseModel):
    client_op_id: str
    device_id: str
    client_seq: int
    op_type: str
    payload: Dict[str, Any]
    client_ts: datetime


class SyncOperationResultItem(BaseModel):
    client_op_id: str
    result: Literal["applied", "replayed", "applied_with_conflict", "rejected"]
    reason: Optional[str] = None


class SyncBatchRequest(BaseModel):
    operations: List[SyncOperationItem]


class SyncBatchResponse(BaseModel):
    results: List[SyncOperationResultItem]


# ==============================================================================
# Monitoring & Alerts
# ==============================================================================

class LiveMonitoringStop(BaseModel):
    id: str
    outlet_id: str
    status: str
    eta: Optional[str] = None
    pod_recorded: bool = False
    projected_arrival: Optional[str] = None
    window_close_time: Optional[str] = None
    parking_constraint: Optional[str] = None
    at_risk: Optional[bool] = False
    arrived_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class LiveMonitoringNextStop(BaseModel):
    outlet_id: Optional[str] = None
    eta: Optional[str] = None


class LiveMonitoringTrip(BaseModel):
    vehicle_id: str
    driver_name: str
    trip_status: str
    brand: str
    district: str
    stops_completed: int
    stops_total: int
    health: Literal["on_schedule", "delayed", "blocked"]
    delay_min: Optional[int] = None
    next_stop: Optional[LiveMonitoringNextStop] = None
    open_exceptions: List[ExceptionResponse] = []
    stops: List[LiveMonitoringStop] = []


class LiveMonitoringResponse(BaseModel):
    last_synced_at: datetime
    trips: List[LiveMonitoringTrip]


class AlertResponseItem(BaseModel):
    id: str
    type: Literal["shortfall", "exception", "repeat_deferral", "sync_conflict", "capacity_shortage"]
    severity: Literal["info", "warning", "critical"]
    status: Literal["open", "resolved"]
    entity_ref: Optional[Dict[str, Any]] = None
    message: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
