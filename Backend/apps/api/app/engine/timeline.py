"""
timeline.py – waiting-aware ETA computation (used by H11, not H8).

Assumptions:
  A1: Fresh trip 1 departs 03:30. Trip 2 departs when trip 1 ends + RELOAD_BUFFER_MIN.
  A3: Style/Tech trips depart so the first arrival >= its window_open_time.
  A4: Two clocks: H8 uses formula (no waiting); H11 uses waiting-aware ETA. Both must pass.
  A5: Stops ordered by earliest window_close_time, then window_open_time, then outlet_id.

Returns a list of StopETA in delivery order.
"""

from __future__ import annotations
from typing import List

from .types import OrderInput, ReferenceData, StopETA
from .formula import (
    compute_trip_minutes,
    hhmm_to_minutes,
    minutes_to_hhmm,
    service_allowance,
)
from .constants import FRESH_DEPART_TIME, RELOAD_BUFFER_MIN


def sort_stops(orders: List[OrderInput], ref: ReferenceData) -> List[OrderInput]:
    """
    A5: Sort by (window_close_time, window_open_time, outlet_id).
    """
    def key(o: OrderInput):
        out = ref.outlets[o.outlet_id]
        return (
            hhmm_to_minutes(out.window_close_time),
            hhmm_to_minutes(out.window_open_time),
            o.outlet_id,
        )
    return sorted(orders, key=key)


def compute_depart_time(
    brand: str,
    trip_no: int,
    prev_trip_end_min: int,
    orders: List[OrderInput],
    ref: ReferenceData,
    district_name: str,
    reload_buffer_min: int = RELOAD_BUFFER_MIN,
) -> int:
    """
    Returns the departure time in minutes from midnight.
    - Fresh trip 1: 03:30.
    - Fresh trip 2: prev_trip_end_min + reload_buffer_min.
    - Style/Tech: depart so first arrival >= first stop window_open_time.
    """
    district_ref = ref.districts[district_name]
    outbound = district_ref.depot_to_district_freeflow_min

    if brand == "Fresh":
        if trip_no == 1:
            return hhmm_to_minutes(FRESH_DEPART_TIME)
        else:
            return prev_trip_end_min + reload_buffer_min
    else:
        # Style or Tech: depart so first arrival (depart + outbound) >= first stop open
        sorted_orders = sort_stops(orders, ref)
        if not sorted_orders:
            return hhmm_to_minutes("09:00")
        first_open = hhmm_to_minutes(ref.outlets[sorted_orders[0].outlet_id].window_open_time)
        # Depart so that depart + outbound = first_open, but not before 09:00 - outbound
        earliest_depart = max(0, first_open - outbound)
        return earliest_depart


def compute_stop_etas(
    orders: List[OrderInput],
    brand: str,
    district_name: str,
    trip_no: int,
    ref: ReferenceData,
    prev_trip_end_min: int = 0,
    reload_buffer_min: int = RELOAD_BUFFER_MIN,
    depart_override_min: int = -1,
) -> List[StopETA]:
    """
    Compute waiting-aware ETAs for each stop (A1, A3, A4, A5).
    Returns stops in delivery order.
    depart_override_min: if >= 0, override the computed depart time.
    """
    if not orders:
        return []

    district_ref = ref.districts[district_name]
    sorted_orders = sort_stops(orders, ref)

    if depart_override_min >= 0:
        depart_min = depart_override_min
    else:
        depart_min = compute_depart_time(
            brand, trip_no, prev_trip_end_min, sorted_orders, ref, district_name, reload_buffer_min
        )

    outbound = district_ref.depot_to_district_freeflow_min
    inter = district_ref.inter_stop_freeflow_min

    etas: List[StopETA] = []
    cursor = depart_min  # current time in minutes from midnight

    for seq, order in enumerate(sorted_orders, start=1):
        outlet = ref.outlets[order.outlet_id]
        if seq == 1:
            arrival = cursor + outbound
        else:
            arrival = cursor + inter  # cursor = previous service_end

        open_min = hhmm_to_minutes(outlet.window_open_time)
        close_min = hhmm_to_minutes(outlet.window_close_time)

        service_start = max(arrival, open_min)
        allow = service_allowance(ref, brand, outlet.dock_type)
        service_end = service_start + allow

        etas.append(StopETA(
            order_id=order.order_id,
            outlet_id=order.outlet_id,
            seq=seq,
            arrival_min=arrival,
            service_start_min=service_start,
            service_end_min=service_end,
            eta_clock=minutes_to_hhmm(arrival),
        ))
        cursor = service_end

    return etas


def trip_end_min(etas: List[StopETA]) -> int:
    """Return the minute-from-midnight when the last stop service ends."""
    if not etas:
        return 0
    return int(etas[-1].service_end_min)
