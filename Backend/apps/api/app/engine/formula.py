"""
formula.py – pure trip-time and fuel calculations.

trip_minutes = depot_to_district_freeflow_min
             + inter_stop_freeflow_min * (n_orders - 1)
             + sum_over_orders(service_allowance_min[brand, outlet.dock_type])

Fuel (A2):
  litres = (2 * depot_to_district_km + inter_stop_km * (n - 1)) / km_per_l

Both formulas are from the booklet; fuel adds the return leg conservatively (A2).
"""

from __future__ import annotations
from typing import List

from .types import DistrictRef, OutletRef, OrderInput, ReferenceData


def service_allowance(ref: ReferenceData, brand: str, dock_type: str) -> int:
    """Returns the service allowance in minutes for the given brand and dock_type."""
    return ref.service_allowance[(brand, dock_type)]


def compute_trip_minutes(
    orders: List[OrderInput],
    district_ref: DistrictRef,
    ref: ReferenceData,
    brand: str,
) -> float:
    """
    Exact booklet formula (no waiting, no return leg).
    brand is the trip brand (H1 enforces all orders share the same brand).
    """
    if not orders:
        return 0.0

    n = len(orders)
    outbound = district_ref.depot_to_district_freeflow_min
    inter = district_ref.inter_stop_freeflow_min * (n - 1)
    allowances = sum(
        service_allowance(ref, brand, ref.outlets[o.outlet_id].dock_type)
        for o in orders
    )
    return float(outbound + inter + allowances)


def compute_trip_fuel(
    n_orders: int,
    district_ref: DistrictRef,
    km_per_l: float,
) -> float:
    """
    Fuel = (2 * depot_to_district_km + inter_stop_km * (n - 1)) / km_per_l
    Includes return leg conservatively (A2).
    """
    km = 2.0 * district_ref.depot_to_district_km + district_ref.inter_stop_km * (n_orders - 1)
    return km / km_per_l


def hhmm_to_minutes(hhmm: str) -> int:
    """Convert HH:MM string to minutes from midnight."""
    h, m = hhmm.split(":")
    return int(h) * 60 + int(m)


def minutes_to_hhmm(total_minutes: float) -> str:
    """Convert minutes from midnight to HH:MM string (wraps at 24h)."""
    total = int(total_minutes) % (24 * 60)
    h = total // 60
    m = total % 60
    return f"{h:02d}:{m:02d}"
