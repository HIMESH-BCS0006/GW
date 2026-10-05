"""
Loader API endpoints for warehouse loading coordination.
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_roles, check_depot_scope
from app.schemas.field import (
    ConfirmLoadRequest,
    CreateLoadCheckRequest,
    LoadCheckResponse,
    LoadListResponse,
)
from app.schemas.planning import (
    TripCard,
    TripResponse,
)
from app.services.loader_service import (
    confirm_trip_load_service,
    get_loading_trips_service,
    get_trip_load_list_service,
    report_load_check_service,
    start_trip_loading_service,
)

router = APIRouter(tags=["loader"])


@router.get(
    "/loading/trips",
    response_model=List[TripCard],
    operation_id="getLoadingTrips",
)
def get_loading_trips_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["loader", "dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return get_loading_trips_service(db, depot_id=target_depot)


@router.get(
    "/trips/{id}/load-list",
    response_model=LoadListResponse,
    operation_id="getTripLoadList",
)
def get_trip_load_list_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["loader", "dispatcher", "driver"])),
    db: Session = Depends(get_db),
):
    return get_trip_load_list_service(db, trip_id=id)


@router.post(
    "/trips/{id}/load-start",
    response_model=TripResponse,
    operation_id="startTripLoading",
)
def start_trip_loading_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["loader", "dispatcher"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "loader")
    return start_trip_loading_service(db, trip_id=id, user_id=user_id)


@router.post(
    "/trips/{id}/load-checks",
    response_model=LoadCheckResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id="reportLoadCheck",
)
def report_load_check_endpoint(
    id: str,
    req: CreateLoadCheckRequest,
    claims: dict = Depends(require_roles(["loader", "dispatcher"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "loader")
    return report_load_check_service(db, trip_id=id, req=req, user_id=user_id)


@router.post(
    "/trips/{id}/load-confirm",
    response_model=TripResponse,
    operation_id="confirmTripLoad",
)
def confirm_trip_load_endpoint(
    id: str,
    req: ConfirmLoadRequest,
    claims: dict = Depends(require_roles(["loader", "dispatcher"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "loader")
    return confirm_trip_load_service(db, trip_id=id, req=req, user_id=user_id)
