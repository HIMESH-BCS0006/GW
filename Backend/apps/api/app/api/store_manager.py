"""
Store Manager API endpoints.
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_roles
from app.schemas.order import (
    CreateOrderRequest,
    CreateOrderResponse,
    OrderResponse,
    CancelOrderRequest,
)
from app.schemas.planning import TripStopResponse
from app.schemas.notification import NotificationResponse
from app.schemas.field import RecordReceiptRequest, ReceiptResponse
from app.services.order_service import (
    create_order,
    list_orders,
    get_order_by_id,
    cancel_order,
    get_outlet_expected_deliveries,
    enrich_order_response,
    record_stop_receipt_service,
)
from app.services.notification_service import (
    get_user_notifications,
    mark_notification_as_read,
)

router = APIRouter(tags=["store_manager"])


@router.post(
    "/orders",
    response_model=CreateOrderResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id="createOrder",
)
def create_order_endpoint(
    req: CreateOrderRequest,
    claims: dict = Depends(require_roles(["store_manager"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "store_manager")
    return create_order(db, req, user_id=user_id)


@router.get(
    "/orders",
    response_model=List[OrderResponse],
    operation_id="listOrders",
)
def list_orders_endpoint(
    claims: dict = Depends(require_roles(["store_manager"])),
    db: Session = Depends(get_db),
):
    outlet_id = claims.get("outlet_id")
    return list_orders(db, outlet_id=outlet_id)


@router.get(
    "/orders/{id}",
    response_model=OrderResponse,
    operation_id="getOrderById",
)
def get_order_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["store_manager", "dispatcher"])),
    db: Session = Depends(get_db),
):
    outlet_id = claims.get("outlet_id") if claims.get("role") == "store_manager" else None
    return get_order_by_id(db, order_id=id, outlet_id=outlet_id)


@router.post(
    "/orders/{id}/cancel",
    response_model=OrderResponse,
    operation_id="cancelOrder",
)
def cancel_order_endpoint(
    id: str,
    req: CancelOrderRequest,
    claims: dict = Depends(require_roles(["store_manager", "dispatcher"])),
    db: Session = Depends(get_db),
):
    outlet_id = claims.get("outlet_id") if claims.get("role") == "store_manager" else None
    return cancel_order(db, order_id=id, req=req, outlet_id=outlet_id)


@router.get(
    "/outlets/{id}/expected-deliveries",
    response_model=List[TripStopResponse],
    operation_id="getOutletExpectedDeliveries",
)
def get_expected_deliveries_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["store_manager", "dispatcher"])),
    db: Session = Depends(get_db),
):
    stops = get_outlet_expected_deliveries(db, outlet_id=id)
    return [TripStopResponse.model_validate(s) for s in stops]


@router.post(
    "/stops/{id}/receipt",
    response_model=ReceiptResponse,
    operation_id="recordStopReceipt",
)
def record_stop_receipt_endpoint(
    id: str,
    req: RecordReceiptRequest,
    claims: dict = Depends(require_roles(["store_manager", "dispatcher"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "store_manager")
    outlet_id = claims.get("outlet_id")
    role = claims.get("role", "store_manager")
    return record_stop_receipt_service(
        db,
        stop_id=id,
        req=req,
        user_id=user_id,
        user_outlet_id=outlet_id,
        user_role=role,
    )


@router.get(
    "/notifications",
    response_model=List[NotificationResponse],
    operation_id="listNotifications",
)
def list_notifications_endpoint(
    claims: dict = Depends(require_roles(["store_manager", "dispatcher", "driver", "loader"])),
    db: Session = Depends(get_db),
):
    role = claims.get("role", "")
    outlet_id = claims.get("outlet_id")
    depot_ids = claims.get("depot_ids", [])
    notifs = get_user_notifications(db, user_role=role, user_outlet_id=outlet_id, user_depot_ids=depot_ids)
    return [NotificationResponse.model_validate(n) for n in notifs]


@router.post(
    "/notifications/{id}/read",
    response_model=NotificationResponse,
    operation_id="markNotificationRead",
)
def mark_notification_read_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["store_manager", "dispatcher", "driver", "loader"])),
    db: Session = Depends(get_db),
):
    notif = mark_notification_as_read(db, notification_id=id)
    if not notif:
        return NotificationResponse(id=id, audience_role=claims.get("role", "store_manager"))
    return NotificationResponse.model_validate(notif)
