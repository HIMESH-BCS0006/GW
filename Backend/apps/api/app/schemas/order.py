"""
Order schemas matching openapi.yaml.
"""

from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class CreateOrderRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    outlet_id: str
    delivery_date: Optional[date] = None
    temp_requirement: str  # chilled | ambient
    order_units: int
    order_weight_kg: Optional[float] = None
    order_volume_m3: Optional[float] = None
    note: Optional[str] = None
    client_op_id: Optional[str] = None


class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    outlet_id: str
    delivery_date: date
    requested_delivery_date: Optional[date] = None
    placed_at: datetime
    status: str
    temp_requirement: str
    order_units: int
    order_weight_kg: float
    order_volume_m3: float
    rolled_over: bool
    deferral_count: int
    cancel_reason: Optional[str] = None
    trip_id: Optional[str] = None
    stop_id: Optional[str] = None
    eta: Optional[str] = None
    receipt_status: Optional[str] = None
    note: Optional[str] = None
    client_op_id: Optional[str] = None


class CreateOrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    order: OrderResponse
    confirmation_code: str
    rolled_over: bool
    requested_delivery_date: Optional[date] = None


class CancelOrderRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    reason: str
    note: Optional[str] = None


class DeferOrderRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    reason_text: str
    note: Optional[str] = None
    reason_code: Optional[str] = "MANUAL"


class BatchRequeueRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    order_ids: list[str]


class DeferralResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    order_id: str
    from_delivery_date: date
    reason_code: str
    reason_class: str
    reason_text: str
    consequence_text: Optional[str] = None
    details_json: Optional[dict] = None
    decided_by: str
    decided_by_user: Optional[str] = None
    decided_at: datetime
    notified_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    resolved_to_date: Optional[date] = None

    # Enriched context fields
    order_status: Optional[str] = "DEFERRED"
    outlet_id: Optional[str] = None
    brand: Optional[str] = None
    district: Optional[str] = None
    temp_requirement: Optional[str] = None
    order_units: Optional[int] = None
    order_weight_kg: Optional[float] = None
    order_volume_m3: Optional[float] = None
    deferral_count: Optional[int] = 0
    is_requeued: Optional[bool] = False

