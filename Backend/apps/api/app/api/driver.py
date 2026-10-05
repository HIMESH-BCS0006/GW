"""
Driver API endpoints for route execution, stop updates, exceptions, and offline sync.
"""

from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_roles
from app.schemas.field import (
    ExceptionResponse,
    RecordStopExceptionRequest,
    RecordStopOutcomeRequest,
    StartTripRequest,
    SyncBatchRequest,
    SyncBatchResponse,
)
from app.schemas.planning import (
    TripCard,
    TripResponse,
    TripStopResponse,
)
from app.services.driver_service import (
    complete_trip_service,
    get_driver_trips_service,
    record_stop_arrival_service,
    record_stop_outcome_service,
    report_stop_exception_service,
    start_trip_service,
)
from app.services.sync_service import sync_offline_operations_service

router = APIRouter(tags=["driver"])


@router.get(
    "/driver/trips",
    response_model=List[TripCard],
    operation_id="getDriverTrips",
)
def get_driver_trips_endpoint(
    claims: dict = Depends(require_roles(["driver", "dispatcher"])),
    db: Session = Depends(get_db),
):
    vehicle_id = claims.get("vehicle_id")
    return get_driver_trips_service(db, vehicle_id=vehicle_id)


@router.post(
    "/trips/{id}/start",
    response_model=TripResponse,
    operation_id="startTrip",
)
def start_trip_endpoint(
    id: str,
    req: StartTripRequest,
    claims: dict = Depends(require_roles(["driver", "dispatcher"])),
    db: Session = Depends(get_db),
):
    vehicle_id = claims.get("vehicle_id")
    role = claims.get("role", "driver")
    return start_trip_service(db, trip_id=id, req=req, user_vehicle_id=vehicle_id, user_role=role)


@router.post(
    "/stops/{id}/arrive",
    response_model=TripStopResponse,
    operation_id="recordStopArrival",
)
def record_stop_arrival_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["driver", "dispatcher"])),
    db: Session = Depends(get_db),
):
    vehicle_id = claims.get("vehicle_id")
    role = claims.get("role", "driver")
    return record_stop_arrival_service(db, stop_id=id, user_vehicle_id=vehicle_id, user_role=role)


@router.post(
    "/stops/{id}/outcome",
    response_model=TripStopResponse,
    operation_id="recordStopOutcome",
)
def record_stop_outcome_endpoint(
    id: str,
    req: RecordStopOutcomeRequest,
    claims: dict = Depends(require_roles(["driver", "dispatcher"])),
    db: Session = Depends(get_db),
):
    vehicle_id = claims.get("vehicle_id")
    role = claims.get("role", "driver")
    return record_stop_outcome_service(db, stop_id=id, req=req, user_vehicle_id=vehicle_id, user_role=role)


@router.post(
    "/stops/{id}/exception",
    response_model=ExceptionResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id="reportStopException",
)
def report_stop_exception_endpoint(
    id: str,
    req: RecordStopExceptionRequest,
    claims: dict = Depends(require_roles(["driver", "dispatcher"])),
    db: Session = Depends(get_db),
):
    vehicle_id = claims.get("vehicle_id")
    role = claims.get("role", "driver")
    return report_stop_exception_service(db, stop_id=id, req=req, user_vehicle_id=vehicle_id, user_role=role)


@router.post(
    "/trips/{id}/complete",
    response_model=TripResponse,
    operation_id="completeTrip",
)
def complete_trip_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["driver", "dispatcher"])),
    db: Session = Depends(get_db),
):
    vehicle_id = claims.get("vehicle_id")
    role = claims.get("role", "driver")
    return complete_trip_service(db, trip_id=id, user_vehicle_id=vehicle_id, user_role=role)


@router.post(
    "/sync",
    response_model=SyncBatchResponse,
    operation_id="syncOfflineOperations",
)
def sync_offline_operations_endpoint(
    req: SyncBatchRequest,
    claims: dict = Depends(require_roles(["driver", "dispatcher", "loader", "store_manager"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "driver")
    vehicle_id = claims.get("vehicle_id")
    role = claims.get("role", "driver")
    return sync_offline_operations_service(db, req=req, user_id=user_id, user_vehicle_id=vehicle_id, user_role=role)
