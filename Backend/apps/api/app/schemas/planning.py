"""
Planning, Trip, Dashboard, and Validation schemas matching openapi.yaml.
"""

from datetime import date, datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class ViolationItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    rule: str
    message: str
    actual: Optional[Any] = None
    limit: Optional[Any] = None


class GeneratePlanRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    depot_id: str
    delivery_date: date
    regenerate: Optional[bool] = False


class PlanRunResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    depot_id: str
    delivery_date: date
    status: str
    version: int
    generated_by: str
    generated_at: datetime
    ranking_config_json: Optional[dict] = None
    summary_json: Optional[dict] = None


class ValidatePlanRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    plan_run_id: str


class ValidatePlanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    valid: bool
    violations: List[ViolationItem] = Field(default_factory=list)


class AddOrderToTripRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    order_id: str


class TripResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    plan_run_id: str
    vehicle_id: str
    depot_id: str
    delivery_date: date
    trip_no: int
    brand: str
    district: str
    status: str
    plan_version: int
    depart_time: Optional[str] = None
    est_minutes: Optional[int] = None
    est_km: Optional[float] = None
    est_fuel_l: Optional[float] = None
    confirmed_by: Optional[str] = None
    confirmed_at: Optional[datetime] = None


class TripStopResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    trip_id: str
    order_id: str
    seq: int
    eta: Optional[str] = None
    service_start_est: Optional[str] = None
    service_min: int
    status: str
    receipt_status: str
    arrived_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    outcome: Optional[str] = None
    quantity_delivered: Optional[int] = None
    received_by: Optional[str] = None
    outcome_note: Optional[str] = None
    device_ts: Optional[datetime] = None


class TripCard(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    plan_run_id: str
    delivery_date: date
    trip_no: int
    brand: str
    district: str
    depot_id: str
    vehicle_id: str
    vehicle_type: str
    vehicle_temp: str
    stop_count: int
    depart_time: Optional[str] = None
    plan_version: int
    status: str
    weight_used_kg: float
    weight_cap_kg: float
    volume_used_m3: float
    volume_cap_m3: float
    est_minutes: Optional[int] = None
    est_fuel_l: Optional[float] = None
    time_budget_min: Optional[int] = None


class StopDetail(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    trip_id: str
    order_id: str
    seq: int
    outlet_id: str
    outlet_name: str
    district: str
    dock_type: str
    parking_constraint: str
    order_units: int
    order_weight_kg: float
    order_volume_m3: float
    window_open_time: str
    window_close_time: str
    eta: Optional[str] = None
    service_start_est: Optional[str] = None
    service_min: int
    status: str
    receipt_status: str
    arrived_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    outcome: Optional[str] = None
    quantity_delivered: Optional[int] = None
    received_by: Optional[str] = None
    outcome_note: Optional[str] = None


class TripDetailResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    trip: TripCard
    stops: List[StopDetail]


class FuelLedgerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    vehicle_id: str
    iso_year: int
    iso_week: int
    litres_committed: float


class VehicleAvailabilityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    vehicle_id: str
    date: date
    status: str
    note: Optional[str] = None


class AlertItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    type: str
    severity: str
    status: str
    entity_ref: Optional[Dict[str, Any]] = None
    message: str
    created_at: datetime


class PlanRunSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    plan_run_id: str
    status: str
    version: int
    trips: int
    orders_served: int
    orders_deferred: int
    deferred_counts: Dict[str, Any]
    capacity: Dict[str, Any]
    reefer: Dict[str, Any]
    fuel: List[Dict[str, Any]]
    constraint_health: Dict[str, Any]


class DashboardSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    date: date
    depot_id: str
    business_now: datetime
    cutoff: Dict[str, Any]
    orders: Dict[str, Any]
    planning_progress: Dict[str, Any]
    vehicles: Dict[str, Any]
    alerts: List[AlertItem]
    active_trips: List[Dict[str, Any]]
