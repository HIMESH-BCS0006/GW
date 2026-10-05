"""
test_priority.py – tests for lexicographic priority ranking per Spec 02 section 4.

Priority hierarchy:
  1. deferred_yesterday = 1
  2. larger days_since_last_served
  3. Fresh chilled > Fresh ambient > Style > Tech
  4. earlier window_close_time
  5. cheaper service cost proxy
  6. stable tie-break by order_id
"""

import pytest
from app.engine.priority import rank_orders
from app.engine.types import OrderInput, ReferenceData


def make_test_order(
    order_id: str,
    outlet_id: str,
    brand: str = "Fresh",
    temp: str = "ambient",
    deferred_yesterday: bool = False,
    days_since_last_served: int = 0,
):
    return OrderInput(
        order_id=order_id,
        outlet_id=outlet_id,
        brand=brand,
        district="Colombo",
        depot="Peliyagoda",
        temp_requirement=temp,
        order_weight_kg=100.0,
        order_volume_m3=0.5,
        deferred_yesterday=deferred_yesterday,
        days_since_last_served=days_since_last_served,
    )


def test_fairness_deferred_yesterday_beats_not_deferred(ref_data: ReferenceData):
    """Rule 1: deferred_yesterday = 1 served before deferred_yesterday = 0."""
    colombo_fresh = [
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh"
    ]
    o1 = make_test_order("ORD-A", colombo_fresh[0].outlet_id, deferred_yesterday=False, days_since_last_served=5)
    o2 = make_test_order("ORD-B", colombo_fresh[1].outlet_id, deferred_yesterday=True, days_since_last_served=1)

    ranked = rank_orders([o1, o2], ref_data)
    assert ranked[0].order_id == "ORD-B", "Order with deferred_yesterday=True must come first"
    assert ranked[1].order_id == "ORD-A"


def test_days_since_last_served(ref_data: ReferenceData):
    """Rule 2: larger days_since_last_served served first when deferred_yesterday is equal."""
    colombo_fresh = [
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh"
    ]
    o1 = make_test_order("ORD-A", colombo_fresh[0].outlet_id, days_since_last_served=2)
    o2 = make_test_order("ORD-B", colombo_fresh[1].outlet_id, days_since_last_served=7)

    ranked = rank_orders([o1, o2], ref_data)
    assert ranked[0].order_id == "ORD-B", "Order with days_since_last_served=7 must beat days_since_last_served=2"


def test_brand_temp_hierarchy(ref_data: ReferenceData):
    """Rule 3: Fresh chilled > Fresh ambient > Style > Tech."""
    colombo_fresh = next(o for o in ref_data.outlets.values() if o.district == "Colombo" and o.brand == "Fresh")
    colombo_style = next(o for o in ref_data.outlets.values() if o.district == "Colombo" and o.brand == "Style")
    colombo_tech = next(o for o in ref_data.outlets.values() if o.district == "Colombo" and o.brand == "Tech")

    o_tech = make_test_order("ORD-TECH", colombo_tech.outlet_id, brand="Tech", temp="ambient")
    o_style = make_test_order("ORD-STYLE", colombo_style.outlet_id, brand="Style", temp="ambient")
    o_fresh_amb = make_test_order("ORD-FRESH-AMB", colombo_fresh.outlet_id, brand="Fresh", temp="ambient")
    o_fresh_chl = make_test_order("ORD-FRESH-CHL", colombo_fresh.outlet_id, brand="Fresh", temp="chilled")

    ranked = rank_orders([o_tech, o_style, o_fresh_amb, o_fresh_chl], ref_data)
    order_ids = [o.order_id for o in ranked]
    assert order_ids == ["ORD-FRESH-CHL", "ORD-FRESH-AMB", "ORD-STYLE", "ORD-TECH"]


def test_window_close_time_priority(ref_data: ReferenceData):
    """Rule 4: Earlier window_close_time ranked ahead when prior rules tie."""
    # Find two Fresh Colombo outlets with different window close times
    colombo_fresh = [
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.dock_type == "street"
    ]
    # OUT001 has 07:30 close; OUT002 has 08:00 close
    out_730 = next(o for o in colombo_fresh if o.window_close_time == "07:30")
    out_800 = next(o for o in colombo_fresh if o.window_close_time == "08:00")

    o_late = make_test_order("ORD-LATE", out_800.outlet_id)
    o_early = make_test_order("ORD-EARLY", out_730.outlet_id)

    ranked = rank_orders([o_late, o_early], ref_data)
    assert ranked[0].order_id == "ORD-EARLY"
    assert ranked[1].order_id == "ORD-LATE"


def test_tie_break_by_order_id(ref_data: ReferenceData):
    """Rule 6: Final tie-break is stable order_id."""
    outlet = next(o for o in ref_data.outlets.values() if o.district == "Colombo" and o.brand == "Fresh")
    o_z = make_test_order("ORD-Z", outlet.outlet_id)
    o_a = make_test_order("ORD-A", outlet.outlet_id)

    ranked = rank_orders([o_z, o_a], ref_data)
    assert ranked[0].order_id == "ORD-A"
    assert ranked[1].order_id == "ORD-Z"


def test_configurable_ranking_object(ref_data: ReferenceData):
    """Ranking policy is configurable and stored with run."""
    colombo_fresh = [
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh"
    ]
    o1 = make_test_order("ORD-1", colombo_fresh[0].outlet_id, deferred_yesterday=False, days_since_last_served=10)
    o2 = make_test_order("ORD-2", colombo_fresh[1].outlet_id, deferred_yesterday=True, days_since_last_served=1)

    # Invert priority: ignore deferred_yesterday
    custom_config = {
        "p1_deferred_yesterday": False,
        "p2_days_since_last_served": True,
        "p3_brand_temp_order": ["Fresh/chilled", "Fresh/ambient", "Style", "Tech"],
        "p4_window_close_time": True,
        "p5_service_cost": True,
        "p6_order_ref": True,
    }
    ranked = rank_orders([o1, o2], ref_data, config=custom_config)
    assert ranked[0].order_id == "ORD-1", "With p1 disabled, days_since_last_served=10 should win"
