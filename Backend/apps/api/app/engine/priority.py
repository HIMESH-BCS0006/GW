"""
priority.py – lexicographic order ranking per spec section 4.

Priority order (configurable, lexicographic):
  1. deferred_yesterday = 1
  2. larger days_since_last_served
  3. Fresh/chilled first, then Fresh/ambient, then Style, then Tech
  4. earlier window_close_time
  5. cheaper to serve per trip minute (service_allowance / inter_stop = proxy for cost)
  6. final tie-break: order_id (stable, deterministic)

The cost-per-minute proxy is service_allowance_min / 1 (treating each stop as marginal
cost of one inter-stop travel + allowance, since outbound is shared).
"""

from __future__ import annotations
from typing import List

from .constants import DEFAULT_PRIORITY_CONFIG
from .formula import hhmm_to_minutes, service_allowance
from .types import OrderInput, ReferenceData


def _brand_temp_rank(order: OrderInput, config: dict) -> int:
    """Lower rank = higher priority."""
    order_list = config.get("p3_brand_temp_order", DEFAULT_PRIORITY_CONFIG["p3_brand_temp_order"])
    key = f"{order.brand}/{order.temp_requirement}"
    try:
        return order_list.index(key)
    except ValueError:
        # Style or Tech without temp: match just brand
        for i, item in enumerate(order_list):
            if item == order.brand:
                return i
        return len(order_list)


def _cost_proxy(order: OrderInput, ref: ReferenceData, brand: str) -> float:
    """
    Marginal cost proxy: service_allowance_min for this outlet's dock_type.
    Lower is cheaper (higher priority).
    """
    outlet = ref.outlets.get(order.outlet_id)
    if outlet is None:
        return 999.0
    return float(service_allowance(ref, brand, outlet.dock_type))


def rank_orders(
    orders: List[OrderInput],
    ref: ReferenceData,
    config: dict = None,
) -> List[OrderInput]:
    """
    Returns orders sorted by the lexicographic priority rule.
    """
    if config is None:
        config = DEFAULT_PRIORITY_CONFIG

    def sort_key(o: OrderInput):
        outlet = ref.outlets.get(o.outlet_id)
        win_close = hhmm_to_minutes(outlet.window_close_time) if outlet else 9999

        # p1: deferred_yesterday (0 = highest priority because sorted ascending, negate)
        p1 = 0 if (config.get("p1_deferred_yesterday") and o.deferred_yesterday) else 1
        # p2: larger days_since_last_served first → negate
        p2 = -o.days_since_last_served if config.get("p2_days_since_last_served") else 0
        # p3: brand/temp order
        p3 = _brand_temp_rank(o, config)
        # p4: earlier window_close_time
        p4 = win_close if config.get("p4_window_close_time") else 0
        # p5: cheaper service cost
        p5 = _cost_proxy(o, ref, o.brand) if config.get("p5_service_cost") else 0.0
        # p6: stable tie-break by order_id
        p6 = o.order_id

        return (p1, p2, p3, p4, p5, p6)

    return sorted(orders, key=sort_key)
