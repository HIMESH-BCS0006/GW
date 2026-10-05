"""
deferral.py – deferral diagnosis: reason code, class (UNAVOIDABLE vs CHOICE),
plain-language explanation, consequence text.

The class is computed, not assumed:
  - Re-check the order alone against the full available fleet.
  - Infeasible alone → UNAVOIDABLE.
  - Feasible alone → CHOICE (lost to priority or shared capacity).
"""

from __future__ import annotations
from typing import Dict, List, Optional

from .constants import (
    BUDGET_FRESH_MIN,
    BUDGET_STYLE_TECH_MIN,
    DeferralClass,
    DeferralCode,
)
from .formula import (
    compute_trip_fuel,
    compute_trip_minutes,
    hhmm_to_minutes,
)
from .timeline import compute_stop_etas, sort_stops
from .types import (
    DeferralRecord,
    OrderInput,
    ReferenceData,
    VehicleRef,
)


def _is_solo_feasible(
    order: OrderInput,
    vehicles: List[VehicleRef],
    vehicle_statuses: Dict[str, str],
    fuel_committed: Dict[str, float],
    ref: ReferenceData,
) -> bool:
    """
    Can this single order be placed on ANY available vehicle at its depot,
    satisfying H2, H3, H4, H6, H8, H11, H12?
    """
    outlet = ref.outlets.get(order.outlet_id)
    if outlet is None:
        return False

    district_ref = ref.districts.get(order.district)
    if district_ref is None:
        return False

    for vref in vehicles:
        if vehicle_statuses.get(vref.vehicle_id, "available") != "available":
            continue
        if vref.depot != order.depot:
            continue
        # H2
        if order.temp_requirement == "chilled" and vref.temp != "reefer":
            continue
        # H3
        if outlet.parking_constraint == "van_only" and vref.type != "van":
            continue
        # H6
        if order.order_weight_kg > vref.weight_cap_kg:
            continue
        if order.order_volume_m3 > vref.volume_cap_m3:
            continue
        # H8: single stop trip
        trip_mins = compute_trip_minutes([order], district_ref, ref, order.brand)
        if order.brand == "Fresh" and trip_mins > BUDGET_FRESH_MIN:
            continue
        if order.brand in ("Style", "Tech") and trip_mins > BUDGET_STYLE_TECH_MIN:
            continue
        # H11: single stop ETA
        etas = compute_stop_etas(
            [order], order.brand, order.district, 1, ref
        )
        if etas:
            eta = etas[0]
            close_min = hhmm_to_minutes(outlet.window_close_time)
            if eta.arrival_min > close_min:
                continue
        # H12
        fuel_l = compute_trip_fuel(1, district_ref, vref.km_per_l)
        already = fuel_committed.get(vref.vehicle_id, 0.0)
        if already + fuel_l > vref.weekly_fuel_quota_l:
            continue
        # Passed all checks
        return True
    return False


def diagnose_deferral(
    order: OrderInput,
    reason_code: str,
    ref: ReferenceData,
    all_vehicles: List[VehicleRef],
    vehicle_statuses: Dict[str, str],
    fuel_committed: Dict[str, float],
    days_since_last_served: int = 0,
    consecutive_deferrals: int = 0,
    extra_details: Optional[dict] = None,
) -> DeferralRecord:
    """
    Build a DeferralRecord with computed class, plain-language explanation,
    and consequence text.
    """
    outlet = ref.outlets.get(order.outlet_id)
    outlet_name = outlet.outlet_id if outlet else order.outlet_id
    district = order.district

    # Compute class via solo-feasibility test
    solo_feasible = _is_solo_feasible(
        order, all_vehicles, vehicle_statuses, fuel_committed, ref
    )
    if solo_feasible:
        reason_class = DeferralClass.CHOICE
    else:
        reason_class = DeferralClass.UNAVOIDABLE

    # Plain-language explanation
    if reason_code == DeferralCode.NO_REEFER:
        reason_text = (
            f"Order {order.order_id} for {outlet_name} requires refrigerated transport "
            f"(temp=chilled) but no reefer vehicle is available at {order.depot}."
        )
    elif reason_code == DeferralCode.NO_VAN:
        reason_text = (
            f"Order {order.order_id} for {outlet_name} requires a van (van_only outlet) "
            f"but no van is available at {order.depot}."
        )
    elif reason_code == DeferralCode.TOO_LARGE:
        reason_text = (
            f"Order {order.order_id} ({order.order_weight_kg:.1f} kg / "
            f"{order.order_volume_m3:.2f} m³) exceeds the capacity of every eligible "
            f"vehicle at {order.depot}."
        )
    elif reason_code == DeferralCode.WINDOW_INFEASIBLE:
        district_ref = ref.districts.get(district)
        outbound = district_ref.depot_to_district_freeflow_min if district_ref else "?"
        close = outlet.window_close_time if outlet else "?"
        reason_text = (
            f"Order {order.order_id} for {outlet_name} ({district}): outbound travel "
            f"takes {outbound} min; even a single stop cannot arrive by {close}."
        )
    elif reason_code == DeferralCode.CAPACITY_FULL:
        reason_text = (
            f"Order {order.order_id} for {outlet_name} ({district}): all eligible trips "
            f"are full by weight or volume; no room to add this order."
        )
    elif reason_code == DeferralCode.TIME_BUDGET:
        brand = order.brand
        budget = BUDGET_FRESH_MIN if brand == "Fresh" else BUDGET_STYLE_TECH_MIN
        reason_text = (
            f"Order {order.order_id} for {outlet_name} ({district}): adding this order "
            f"would exceed the {budget}-minute budget for {brand} trips."
        )
    elif reason_code == DeferralCode.TRIP_LIMIT:
        reason_text = (
            f"Order {order.order_id} for {outlet_name} ({district}): all eligible vehicles "
            f"have already used both of their daily trip slots."
        )
    elif reason_code == DeferralCode.FUEL_QUOTA:
        reason_text = (
            f"Order {order.order_id} for {outlet_name} ({district}): adding this trip "
            f"would exceed the weekly fuel quota of the only eligible vehicle."
        )
    else:
        reason_text = (
            f"Order {order.order_id} for {outlet_name} deferred: {reason_code}."
        )

    # Consequence text
    consequence_parts = []
    if days_since_last_served > 0:
        consequence_parts.append(
            f"This outlet has not been served for {days_since_last_served} day(s)."
        )
    if consecutive_deferrals > 0:
        consequence_parts.append(
            f"This is consecutive deferral #{consecutive_deferrals + 1}."
        )
        if consecutive_deferrals >= 1:
            consequence_parts.append(
                "A second consecutive deferral triggers a dispatcher alert."
            )
    consequence_text = " ".join(consequence_parts) if consequence_parts else "No prior deferrals."

    details = extra_details or {}
    details["solo_feasible"] = solo_feasible

    return DeferralRecord(
        order_id=order.order_id,
        outlet_id=order.outlet_id,
        reason_code=reason_code,
        reason_class=reason_class,
        reason_text=reason_text,
        consequence_text=consequence_text,
        details=details,
    )
