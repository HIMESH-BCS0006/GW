"""
validator.py – H1-H12 hard constraint validator.

One validator is shared by the allocator (during planning) and API handlers (manual edits).
Returns ValidationResult with every violation as {rule, message, actual, limit}.

H1  same brand and district
H2  chilled needs reefer
H3  van_only needs van
H4  vehicle from same depot
H5  whole orders (structural; enforced by design)
H6  weight and volume capacity
H7  at most 2 trips per vehicle per day
H8  time budget (formula, no waiting)
H9  vehicle status available
H10 operating calendar day
H11 arrival within outlet window (waiting-aware ETA)
H12 weekly fuel quota

A10: mall windows are never overridable.
"""

from __future__ import annotations
from typing import Dict, List, Optional

from .constants import (
    BUDGET_FRESH_MIN,
    BUDGET_STYLE_TECH_MIN,
    MAX_TRIPS_PER_VEHICLE_PER_DAY,
    RULES,
)
from .formula import (
    compute_trip_minutes,
    compute_trip_fuel,
    hhmm_to_minutes,
)
from .timeline import compute_stop_etas, sort_stops
from .types import (
    AllocatorInput,
    OrderInput,
    ReferenceData,
    TripPlan,
    ValidationResult,
    VehicleRef,
    ViolationDetail,
)


def _violation(rule: str, message: str, actual: float, limit: float) -> ViolationDetail:
    return ViolationDetail(rule=rule, message=message, actual=actual, limit=limit)


def validate_trip(
    trip: TripPlan,
    ref: ReferenceData,
    vehicle_ref: VehicleRef,
    vehicle_status: str,
    is_operating: bool,
    fuel_already_committed_l: float,
    fresh_budget_used: float,
    style_tech_budget_used: float,
    prev_trip_end_min: int = 0,
    trip_count_for_vehicle: int = 1,
    reload_buffer_min: int = 0,
) -> ValidationResult:
    """
    Validates a single TripPlan against H1-H12.
    """
    violations: List[ViolationDetail] = []

    if not trip.orders:
        return ValidationResult(is_valid=True)

    district_ref = ref.districts.get(trip.district)
    if district_ref is None:
        violations.append(_violation("H4", f"Unknown district: {trip.district}", 0, 0))
        return ValidationResult(is_valid=False, violations=violations)

    # H10: operating day
    if not is_operating:
        violations.append(_violation("H10", "Delivery date is not an operating day", 0, 1))

    # H9: vehicle available
    if vehicle_status != "available":
        violations.append(_violation(
            "H9", f"Vehicle {vehicle_ref.vehicle_id} is {vehicle_status}", 0, 1
        ))

    # H4: depot match
    if vehicle_ref.depot != trip.depot:
        violations.append(_violation(
            "H4",
            f"Vehicle depot {vehicle_ref.depot} != trip depot {trip.depot}",
            0, 1
        ))

    # H7: trip count
    if trip_count_for_vehicle > MAX_TRIPS_PER_VEHICLE_PER_DAY:
        violations.append(_violation(
            "H7",
            f"Vehicle already has {trip_count_for_vehicle} trips; max {MAX_TRIPS_PER_VEHICLE_PER_DAY}",
            trip_count_for_vehicle,
            MAX_TRIPS_PER_VEHICLE_PER_DAY,
        ))

    # H1: all orders same brand and district
    for order in trip.orders:
        if order.brand != trip.brand:
            violations.append(_violation(
                "H1",
                f"Order {order.order_id} brand {order.brand} != trip brand {trip.brand}",
                0, 1
            ))
        if order.district != trip.district:
            violations.append(_violation(
                "H1",
                f"Order {order.order_id} district {order.district} != trip district {trip.district}",
                0, 1
            ))
        if order.depot != trip.depot:
            violations.append(_violation(
                "H4",
                f"Order {order.order_id} depot {order.depot} != trip depot {trip.depot}",
                0, 1
            ))

    # H2: chilled orders need reefer
    for order in trip.orders:
        if order.temp_requirement == "chilled" and vehicle_ref.temp != "reefer":
            violations.append(_violation(
                "H2",
                f"Order {order.order_id} is chilled but vehicle {vehicle_ref.vehicle_id} is {vehicle_ref.temp}",
                0, 1
            ))

    # H3: van_only outlets need van
    for order in trip.orders:
        outlet = ref.outlets.get(order.outlet_id)
        if outlet and outlet.parking_constraint == "van_only" and vehicle_ref.type != "van":
            violations.append(_violation(
                "H3",
                f"Outlet {order.outlet_id} is van_only but vehicle is {vehicle_ref.type}",
                0, 1
            ))

    # H6: weight and volume
    total_weight = sum(o.order_weight_kg for o in trip.orders)
    total_volume = sum(o.order_volume_m3 for o in trip.orders)
    if total_weight > vehicle_ref.weight_cap_kg:
        violations.append(_violation(
            "H6",
            f"Total weight {total_weight:.1f} kg exceeds capacity {vehicle_ref.weight_cap_kg:.1f} kg",
            total_weight,
            vehicle_ref.weight_cap_kg,
        ))
    if total_volume > vehicle_ref.volume_cap_m3:
        violations.append(_violation(
            "H6",
            f"Total volume {total_volume:.2f} m³ exceeds capacity {vehicle_ref.volume_cap_m3:.2f} m³",
            total_volume,
            vehicle_ref.volume_cap_m3,
        ))

    # H8: time budget (formula, no waiting)
    trip_mins = compute_trip_minutes(trip.orders, district_ref, ref, trip.brand)
    if trip.brand == "Fresh":
        new_fresh_total = fresh_budget_used + trip_mins
        if new_fresh_total > BUDGET_FRESH_MIN:
            violations.append(_violation(
                "H8",
                f"Fresh trip {trip_mins:.0f} min would bring total to {new_fresh_total:.0f} min (budget {BUDGET_FRESH_MIN})",
                new_fresh_total,
                BUDGET_FRESH_MIN,
            ))
    else:
        new_st_total = style_tech_budget_used + trip_mins
        if new_st_total > BUDGET_STYLE_TECH_MIN:
            violations.append(_violation(
                "H8",
                f"Style/Tech trip {trip_mins:.0f} min would bring total to {new_st_total:.0f} min (budget {BUDGET_STYLE_TECH_MIN})",
                new_st_total,
                BUDGET_STYLE_TECH_MIN,
            ))

    # H11: waiting-aware ETA; arrival within window
    etas = compute_stop_etas(
        trip.orders,
        trip.brand,
        trip.district,
        trip.trip_no,
        ref,
        prev_trip_end_min=prev_trip_end_min,
        reload_buffer_min=reload_buffer_min,
    )
    for eta in etas:
        outlet = ref.outlets.get(eta.outlet_id)
        if outlet is None:
            continue
        open_min = hhmm_to_minutes(outlet.window_open_time)
        close_min = hhmm_to_minutes(outlet.window_close_time)
        if eta.arrival_min > close_min:
            violations.append(_violation(
                "H11",
                f"Stop {eta.outlet_id} arrival {eta.arrival_min:.0f} min after window close {close_min}",
                eta.arrival_min,
                close_min,
            ))

    # H12: weekly fuel quota
    fuel_l = compute_trip_fuel(len(trip.orders), district_ref, vehicle_ref.km_per_l)
    total_fuel = fuel_already_committed_l + fuel_l
    if total_fuel > vehicle_ref.weekly_fuel_quota_l:
        violations.append(_violation(
            "H12",
            f"Fuel {total_fuel:.1f} L would exceed weekly quota {vehicle_ref.weekly_fuel_quota_l:.1f} L",
            total_fuel,
            vehicle_ref.weekly_fuel_quota_l,
        ))

    return ValidationResult(is_valid=len(violations) == 0, violations=violations)


def validate_plan(
    trips: List[TripPlan],
    inp: AllocatorInput,
    vehicle_statuses: Dict[str, str],
    prev_fresh_end_min: Dict[str, int],
) -> ValidationResult:
    """
    Validate all trips together (H7, H8 budgets are per-vehicle and per-vehicle-per-day).
    Collects all violations.
    """
    all_violations: List[ViolationDetail] = []
    ref = inp.reference

    # Build per-vehicle trip counts, fuel committed
    vehicle_trip_count: Dict[str, int] = {}
    fuel_committed: Dict[str, float] = {}  # total for the week

    for ledger in inp.fuel_ledger:
        fuel_committed[ledger.vehicle_id] = ledger.litres_committed

    # Aggregate budget tracking per vehicle
    fresh_budget: Dict[str, float] = {}    # total formula minutes of Fresh trips
    style_tech_budget: Dict[str, float] = {}

    for trip in trips:
        vid = trip.vehicle_id
        vehicle_trip_count[vid] = vehicle_trip_count.get(vid, 0) + 1

    for trip in trips:
        vid = trip.vehicle_id
        vref = ref.vehicles.get(vid)
        if vref is None:
            all_violations.append(_violation("H9", f"Unknown vehicle {vid}", 0, 1))
            continue

        status = vehicle_statuses.get(vid, "available")
        trip_count = vehicle_trip_count.get(vid, 1)
        fuel_so_far = fuel_committed.get(vid, 0.0)

        if trip.brand == "Fresh":
            fb = fresh_budget.get(vid, 0.0)
            stb = style_tech_budget.get(vid, 0.0)
        else:
            fb = fresh_budget.get(vid, 0.0)
            stb = style_tech_budget.get(vid, 0.0)

        prev_end = prev_fresh_end_min.get(vid, 0)

        result = validate_trip(
            trip=trip,
            ref=ref,
            vehicle_ref=vref,
            vehicle_status=status,
            is_operating=inp.is_operating,
            fuel_already_committed_l=fuel_so_far,
            fresh_budget_used=fb,
            style_tech_budget_used=stb,
            prev_trip_end_min=prev_end,
            trip_count_for_vehicle=trip_count,
            reload_buffer_min=inp.reload_buffer_min,
        )
        all_violations.extend(result.violations)

        # Update running totals
        district_ref = ref.districts.get(trip.district)
        if district_ref:
            mins = compute_trip_minutes(trip.orders, district_ref, ref, trip.brand)
            fuel = compute_trip_fuel(len(trip.orders), district_ref, vref.km_per_l)
            fuel_committed[vid] = fuel_committed.get(vid, 0.0) + fuel
            if trip.brand == "Fresh":
                fresh_budget[vid] = fresh_budget.get(vid, 0.0) + mins
            else:
                style_tech_budget[vid] = style_tech_budget.get(vid, 0.0) + mins

    return ValidationResult(is_valid=len(all_violations) == 0, violations=all_violations)
