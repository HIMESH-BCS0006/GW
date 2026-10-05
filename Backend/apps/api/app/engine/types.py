"""
types.py – pure dataclasses for engine inputs and outputs.
No database, HTTP or framework imports.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, List, Optional


# ---------------------------------------------------------------------------
# Reference data (read from the database, passed into the engine)
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class DistrictRef:
    district: str
    depot: str
    depot_to_district_km: float
    depot_to_district_freeflow_min: int
    inter_stop_km: float
    inter_stop_freeflow_min: int


@dataclass(frozen=True)
class OutletRef:
    outlet_id: str
    brand: str
    district: str
    depot: str
    dock_type: str                  # rear_dock | street | mall_bay
    parking_constraint: str         # normal | van_only | mall_dock
    window_open_time: str           # HH:MM
    window_close_time: str          # HH:MM


@dataclass(frozen=True)
class VehicleRef:
    vehicle_id: str
    type: str                       # truck | van
    temp: str                       # ambient | reefer
    weight_cap_kg: float
    volume_cap_m3: float
    km_per_l: float
    weekly_fuel_quota_l: float
    depot: str


@dataclass(frozen=True)
class ReferenceData:
    """All reference tables the engine needs. Loaded once per call from the DB."""
    districts: Dict[str, DistrictRef]           # keyed by district name
    outlets: Dict[str, OutletRef]               # keyed by outlet_id
    vehicles: Dict[str, VehicleRef]             # keyed by vehicle_id
    service_allowance: Dict[tuple, int]         # (brand, dock_type) -> minutes


# ---------------------------------------------------------------------------
# Input structs
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class OrderInput:
    order_id: str
    outlet_id: str
    brand: str
    district: str
    depot: str
    temp_requirement: str           # ambient | chilled
    order_weight_kg: float
    order_volume_m3: float
    deferred_yesterday: bool = False
    days_since_last_served: int = 0


@dataclass(frozen=True)
class VehicleSlot:
    """A vehicle slot (vehicle + trip_no 1 or 2) with current committed resources."""
    vehicle_id: str
    trip_no: int                    # 1 or 2
    vehicle_ref: VehicleRef
    used_weight_kg: float = 0.0
    used_volume_m3: float = 0.0
    current_trip_minutes: float = 0.0
    current_fuel_l: float = 0.0
    orders: List[OrderInput] = field(default_factory=list)
    brand: Optional[str] = None     # set when first order added
    district: Optional[str] = None  # set when first order added
    is_locked: bool = False         # CONFIRMED or later → cannot be modified


@dataclass(frozen=True)
class WeeklyFuelLedger:
    """Litres already committed for the ISO week by vehicle."""
    vehicle_id: str
    iso_year: int
    iso_week: int
    litres_committed: float


@dataclass(frozen=True)
class AllocatorInput:
    """Everything the allocator needs for one run."""
    depot: str
    delivery_date: str                      # YYYY-MM-DD
    iso_year: int
    iso_week: int
    is_operating: bool
    orders: List[OrderInput]
    available_vehicle_ids: List[str]        # status = available
    locked_slots: List[VehicleSlot]         # CONFIRMED or later; engine must not modify
    fuel_ledger: List[WeeklyFuelLedger]
    reference: ReferenceData
    priority_config: Optional[dict] = None  # None → use DEFAULT_PRIORITY_CONFIG
    reload_buffer_min: int = 0


# ---------------------------------------------------------------------------
# Output structs
# ---------------------------------------------------------------------------

@dataclass
class ViolationDetail:
    rule: str
    message: str
    actual: float
    limit: float


@dataclass
class ValidationResult:
    is_valid: bool
    violations: List[ViolationDetail] = field(default_factory=list)


@dataclass
class StopETA:
    order_id: str
    outlet_id: str
    seq: int
    arrival_min: float              # minutes from depot departure
    service_start_min: float        # after waiting if early
    service_end_min: float
    eta_clock: str                  # HH:MM Asia/Colombo (computed from depart_time)


@dataclass
class TripPlan:
    """One planned trip."""
    trip_key: str                   # "{vehicle_id}_trip{trip_no}"
    vehicle_id: str
    trip_no: int
    brand: str
    district: str
    depot: str
    orders: List[OrderInput] = field(default_factory=list)
    stops: List[StopETA] = field(default_factory=list)
    trip_minutes: float = 0.0       # formula time (no waiting)
    est_fuel_l: float = 0.0
    total_weight_kg: float = 0.0
    total_volume_m3: float = 0.0
    depart_time: str = ""           # HH:MM


@dataclass
class DeferralRecord:
    order_id: str
    outlet_id: str
    reason_code: str
    reason_class: str               # UNAVOIDABLE | CHOICE
    reason_text: str                # plain language with exact numbers
    consequence_text: str           # days since last served, consecutive deferrals
    details: dict = field(default_factory=dict)


@dataclass
class AllocatorOutput:
    trips: List[TripPlan] = field(default_factory=list)
    deferrals: List[DeferralRecord] = field(default_factory=list)
    validation: Optional[ValidationResult] = None
    # notifications (populated by caller layer, not the engine)
    needs_alert: List[str] = field(default_factory=list)  # order_ids needing dispatcher alert
