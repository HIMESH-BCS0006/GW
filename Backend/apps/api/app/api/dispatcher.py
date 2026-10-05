"""
Dispatcher Planning and Monitoring API endpoints.
"""

from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_roles, check_depot_scope
from app.models.domain import PlanRun
from app.schemas.order import (
    BatchRequeueRequest,
    DeferOrderRequest,
    DeferralResponse,
    OrderResponse,
)
from app.schemas.planning import (
    AddOrderToTripRequest,
    DashboardSummary,
    FuelLedgerResponse,
    GeneratePlanRequest,
    PlanRunResponse,
    PlanRunSummaryResponse,
    TripDetailResponse,
    TripResponse,
    ValidatePlanRequest,
    ValidatePlanResponse,
    VehicleAvailabilityResponse,
)
from app.schemas.field import (
    AlertResponseItem,
    ExceptionDecisionRequest,
    ExceptionResponse,
    LiveMonitoringResponse,
    LoadCheckResponse,
    ResolveLoadCheckRequest,
)
from app.services.order_service import (
    batch_requeue_orders,
    defer_order_manually,
    enrich_order_response,
    requeue_order,
)
from app.services.planning_service import (
    add_order_to_trip_service,
    cancel_trip_service,
    close_plan_run_service,
    confirm_trip_service,
    generate_plan_service,
    get_dashboard_service,
    get_dispatch_queue_service,
    get_fleet_availability_service,
    get_fuel_state_service,
    get_plan_run_trips_service,
    get_plans_summary_service,
    list_plans_service,
    remove_order_from_trip_service,
    validate_plan_service,
)
from app.services.monitoring_service import (
    get_live_monitoring_service,
    get_outlet_skip_history_service,
    list_alerts_service,
    list_deferrals_service,
    list_load_checks_service,
    resolve_exception_decision_service,
)
from app.services.loader_service import resolve_load_check_service

router = APIRouter(tags=["dispatcher"])


@router.get(
    "/dashboard",
    response_model=DashboardSummary,
    operation_id="getDashboard",
)
def get_dashboard_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return get_dashboard_service(db, depot_id=target_depot)


@router.get(
    "/dispatch/queue",
    response_model=List[OrderResponse],
    operation_id="getDispatchQueue",
)
def get_dispatch_queue_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    orders = get_dispatch_queue_service(db, depot_id=target_depot)
    return [enrich_order_response(o, db) for o in orders]


@router.post(
    "/plans/generate",
    response_model=PlanRunResponse,
    operation_id="generatePlan",
)
def generate_plan_endpoint(
    req: GeneratePlanRequest,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    check_depot_scope(req.depot_id, claims)
    user_id = claims.get("user_id") or claims.get("sub", "dispatcher")
    return generate_plan_service(db, req, user_id=user_id)


@router.get(
    "/plans",
    response_model=List[PlanRunResponse],
    operation_id="listPlans",
)
def list_plans_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return list_plans_service(db, depot_id=target_depot)


@router.get(
    "/plans/{plan_run_id}/trips",
    response_model=List[TripDetailResponse],
    operation_id="getPlanRunTrips",
)
def get_plan_run_trips_endpoint(
    plan_run_id: str,
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    if depot_id:
        target_depot = check_depot_scope(depot_id, claims)
    else:
        plan_run = db.query(PlanRun).filter_by(id=plan_run_id).first()
        if plan_run:
            check_depot_scope(plan_run.depot_id, claims)
            target_depot = plan_run.depot_id
        else:
            target_depot = None
    return get_plan_run_trips_service(db, plan_run_id=plan_run_id, depot_id=target_depot)


@router.post(
    "/plans/validate",
    response_model=ValidatePlanResponse,
    operation_id="validatePlan",
)
def validate_plan_endpoint(
    req: ValidatePlanRequest,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    return validate_plan_service(db, req)


@router.post(
    "/trips/{id}/orders",
    response_model=TripResponse,
    operation_id="addOrderToTrip",
)
def add_order_to_trip_endpoint(
    id: str,
    req: AddOrderToTripRequest,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    return add_order_to_trip_service(db, trip_id=id, order_id=req.order_id)


@router.delete(
    "/trips/{id}/orders/{order_id}",
    response_model=TripResponse,
    operation_id="removeOrderFromTrip",
)
def remove_order_from_trip_endpoint(
    id: str,
    order_id: str,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    return remove_order_from_trip_service(db, trip_id=id, order_id=order_id)


@router.post(
    "/orders/{id}/defer",
    response_model=DeferralResponse,
    operation_id="deferOrder",
)
def defer_order_endpoint(
    id: str,
    req: DeferOrderRequest,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "dispatcher")
    return defer_order_manually(db, order_id=id, req=req, user_id=user_id)


@router.post(
    "/orders/{id}/requeue",
    response_model=OrderResponse,
    operation_id="requeueOrder",
)
def requeue_order_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    return requeue_order(db, order_id=id)


@router.post(
    "/orders/batch-requeue",
    response_model=List[OrderResponse],
    operation_id="batchRequeueOrders",
)
def batch_requeue_orders_endpoint(
    req: BatchRequeueRequest,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    return batch_requeue_orders(db, order_ids=req.order_ids)


@router.post(
    "/deferrals/requeue",
    response_model=List[OrderResponse],
    operation_id="requeueDeferrals",
)
def requeue_deferrals_endpoint(
    req: BatchRequeueRequest,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    return batch_requeue_orders(db, order_ids=req.order_ids)



@router.post(
    "/trips/{id}/confirm",
    response_model=TripDetailResponse,
    operation_id="confirmTrip",
)
def confirm_trip_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "dispatcher")
    return confirm_trip_service(db, trip_id=id, user_id=user_id)


@router.post(
    "/trips/{id}/cancel",
    response_model=TripResponse,
    operation_id="cancelTrip",
)
def cancel_trip_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    return cancel_trip_service(db, trip_id=id)


@router.post(
    "/plans/close-run",
    response_model=PlanRunResponse,
    operation_id="closePlanRun",
)
def close_plan_run_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    user_id = claims.get("user_id") or claims.get("sub", "dispatcher")
    return close_plan_run_service(db, depot_id=target_depot, user_id=user_id)


@router.get(
    "/plans/summary",
    response_model=PlanRunSummaryResponse,
    operation_id="getPlansSummary",
)
def get_plans_summary_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return get_plans_summary_service(db, depot_id=target_depot)


@router.get(
    "/fuel",
    response_model=List[FuelLedgerResponse],
    operation_id="getFuelState",
)
def get_fuel_state_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return get_fuel_state_service(db, depot_id=target_depot)


@router.get(
    "/fleet",
    response_model=List[VehicleAvailabilityResponse],
    operation_id="getFleetAvailability",
)
def get_fleet_availability_endpoint(
    depot_id: Optional[str] = Query(None),
    date: Optional[date] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return get_fleet_availability_service(db, depot_id=target_depot, target_date=date)


@router.get(
    "/monitoring/live",
    response_model=LiveMonitoringResponse,
    operation_id="getLiveMonitoring",
)
def get_live_monitoring_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return get_live_monitoring_service(db, depot_id=target_depot)


@router.get(
    "/alerts",
    response_model=List[AlertResponseItem],
    operation_id="listAlerts",
)
def list_alerts_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return list_alerts_service(db, depot_id=target_depot)


@router.post(
    "/exceptions/{id}/decision",
    response_model=ExceptionResponse,
    operation_id="resolveExceptionDecision",
)
def resolve_exception_decision_endpoint(
    id: str,
    req: ExceptionDecisionRequest,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "dispatcher")
    return resolve_exception_decision_service(db, exception_id=id, req=req, user_id=user_id)


@router.get(
    "/load-checks",
    response_model=List[LoadCheckResponse],
    operation_id="listLoadChecks",
)
def list_load_checks_endpoint(
    status: Optional[str] = Query(None),
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher", "loader"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return list_load_checks_service(db, status=status, depot_id=target_depot)


@router.post(
    "/load-checks/{id}/resolve",
    response_model=LoadCheckResponse,
    operation_id="resolveLoadCheck",
)
def resolve_load_check_endpoint(
    id: str,
    req: ResolveLoadCheckRequest,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    user_id = claims.get("user_id") or claims.get("sub", "dispatcher")
    return resolve_load_check_service(db, load_check_id=id, req=req, user_id=user_id)


@router.get(
    "/deferrals",
    response_model=List[DeferralResponse],
    operation_id="listDeferrals",
)
def list_deferrals_endpoint(
    depot_id: Optional[str] = Query(None),
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    target_depot = check_depot_scope(depot_id, claims)
    return list_deferrals_service(db, depot_id=target_depot)


@router.get(
    "/outlets/{id}/skip-history",
    response_model=List[DeferralResponse],
    operation_id="getOutletSkipHistory",
)
def get_outlet_skip_history_endpoint(
    id: str,
    claims: dict = Depends(require_roles(["dispatcher"])),
    db: Session = Depends(get_db),
):
    return get_outlet_skip_history_service(db, outlet_id=id)
