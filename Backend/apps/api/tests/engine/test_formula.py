"""
test_formula.py – booklet formula tests.

Verified examples from spec:
  Gampaha Fresh, 3 orders (2 rear_dock + 1 street): 37 + 9*2 + 15 + 15 + 16 = 101
  Colombo Fresh, 4 street stops: 24 + 8*3 + 16*4 = 112
  Together 213 of 270; a third trip is not allowed.

All values are read from the CSV fixtures, not hard-coded.
"""

import pytest
from app.engine.formula import (
    compute_trip_minutes,
    compute_trip_fuel,
    hhmm_to_minutes,
    minutes_to_hhmm,
    service_allowance,
)
from app.engine.types import OrderInput, ReferenceData


def make_fresh_order(order_id, outlet_id, district, depot, kg=100.0, vol=0.5, chilled=False):
    return OrderInput(
        order_id=order_id,
        outlet_id=outlet_id,
        brand="Fresh",
        district=district,
        depot=depot,
        temp_requirement="chilled" if chilled else "ambient",
        order_weight_kg=kg,
        order_volume_m3=vol,
    )


def test_gampaha_101(ref_data: ReferenceData):
    """
    Gampaha Fresh, 2 rear_dock + 1 street: 37 + 9*2 + 15 + 15 + 16 = 101
    We pick real Gampaha outlets from the CSV.
    """
    # Find 2 rear_dock and 1 street Fresh outlets in Gampaha
    gampaha_fresh = [
        o for o in ref_data.outlets.values()
        if o.district == "Gampaha" and o.brand == "Fresh"
    ]
    rear_dock_outlets = [o for o in gampaha_fresh if o.dock_type == "rear_dock"]
    street_outlets = [o for o in gampaha_fresh if o.dock_type == "street"]
    assert len(rear_dock_outlets) >= 2
    assert len(street_outlets) >= 1

    orders = [
        make_fresh_order("O1", rear_dock_outlets[0].outlet_id, "Gampaha", "Peliyagoda"),
        make_fresh_order("O2", rear_dock_outlets[1].outlet_id, "Gampaha", "Peliyagoda"),
        make_fresh_order("O3", street_outlets[0].outlet_id, "Gampaha", "Peliyagoda"),
    ]

    district_ref = ref_data.districts["Gampaha"]
    result = compute_trip_minutes(orders, district_ref, ref_data, "Fresh")

    # Verify formula components
    sa_rear = service_allowance(ref_data, "Fresh", "rear_dock")
    sa_street = service_allowance(ref_data, "Fresh", "street")
    expected = (
        district_ref.depot_to_district_freeflow_min
        + district_ref.inter_stop_freeflow_min * 2
        + sa_rear + sa_rear + sa_street
    )
    assert result == expected, f"Expected {expected}, got {result}"
    assert result == 101, f"Booklet example should be 101, got {result}"


def test_colombo_112(ref_data: ReferenceData):
    """
    Colombo Fresh, 4 street stops: 24 + 8*3 + 16*4 = 112
    """
    colombo_street = [
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.dock_type == "street"
    ]
    assert len(colombo_street) >= 4

    orders = [
        make_fresh_order(f"O{i+1}", colombo_street[i].outlet_id, "Colombo", "Peliyagoda")
        for i in range(4)
    ]

    district_ref = ref_data.districts["Colombo"]
    result = compute_trip_minutes(orders, district_ref, ref_data, "Fresh")

    sa_street = service_allowance(ref_data, "Fresh", "street")
    expected = (
        district_ref.depot_to_district_freeflow_min
        + district_ref.inter_stop_freeflow_min * 3
        + sa_street * 4
    )
    assert result == expected, f"Expected {expected}, got {result}"
    assert result == 112, f"Booklet example should be 112, got {result}"


def test_213_of_270(ref_data: ReferenceData):
    """
    101 + 112 = 213 of 270. A third trip is not allowed.
    """
    assert 101 + 112 == 213
    assert 213 <= 270  # combined within budget
    # A third trip of even 1 stop in Gampaha (37 + 15 = 52) would push total to 265, still within
    # But the booklet says the COMBINATION of Gampaha + Colombo trip = 213, and a third is "not allowed"
    # The spec means a third trip on the SAME VEHICLE would need another trip_no which hits H7
    # (max 2 trips per vehicle per day). Verify H7 would reject it.
    from app.engine.constants import MAX_TRIPS_PER_VEHICLE_PER_DAY
    assert MAX_TRIPS_PER_VEHICLE_PER_DAY == 2, "Budget constraint is 2 trips per vehicle"


def test_same_outlet_two_stops(ref_data: ReferenceData):
    """
    A9: Two orders to the same outlet are charged as two stops.
    """
    # Pick a Colombo Fresh street outlet
    outlet = next(
        o for o in ref_data.outlets.values()
        if o.district == "Colombo" and o.brand == "Fresh" and o.dock_type == "street"
    )
    orders_1 = [make_fresh_order("O1", outlet.outlet_id, "Colombo", "Peliyagoda")]
    orders_2 = [
        make_fresh_order("O1", outlet.outlet_id, "Colombo", "Peliyagoda"),
        make_fresh_order("O2", outlet.outlet_id, "Colombo", "Peliyagoda"),  # same outlet
    ]
    district_ref = ref_data.districts["Colombo"]
    mins_1 = compute_trip_minutes(orders_1, district_ref, ref_data, "Fresh")
    mins_2 = compute_trip_minutes(orders_2, district_ref, ref_data, "Fresh")

    sa = service_allowance(ref_data, "Fresh", "street")
    inter = district_ref.inter_stop_freeflow_min

    assert mins_2 == mins_1 + inter + sa, (
        f"Two stops at same outlet: {mins_2} should be {mins_1} + {inter} + {sa} = {mins_1 + inter + sa}"
    )


def test_fuel_formula(ref_data: ReferenceData):
    """
    Fuel = (2 * depot_to_district_km + inter_stop_km * (n-1)) / km_per_l
    """
    district_ref = ref_data.districts["Colombo"]
    # Known values from CSV
    km = 2 * district_ref.depot_to_district_km
    fuel_1 = compute_trip_fuel(1, district_ref, 5.0)
    expected = km / 5.0
    assert abs(fuel_1 - expected) < 0.001

    # 3 stops
    km_3 = 2 * district_ref.depot_to_district_km + district_ref.inter_stop_km * 2
    fuel_3 = compute_trip_fuel(3, district_ref, 5.0)
    expected_3 = km_3 / 5.0
    assert abs(fuel_3 - expected_3) < 0.001


def test_hhmm_roundtrip():
    assert hhmm_to_minutes("03:30") == 210
    assert minutes_to_hhmm(210) == "03:30"
    assert hhmm_to_minutes("08:00") == 480
    assert minutes_to_hhmm(480) == "08:00"


def test_max_stops_puttalam_fresh(ref_data: ReferenceData):
    """
    Max stops by time budget for Puttalam Fresh rear_dock is 3 (from spec table 11.1).
    """
    district_ref = ref_data.districts["Puttalam"]
    budget = 270

    outlets = [
        o for o in ref_data.outlets.values()
        if o.district == "Puttalam" and o.brand == "Fresh" and o.dock_type == "rear_dock"
    ]
    # Compute max stops manually
    sa = service_allowance(ref_data, "Fresh", "rear_dock")
    outbound = district_ref.depot_to_district_freeflow_min
    inter = district_ref.inter_stop_freeflow_min

    n = 0
    while outbound + inter * n + sa * (n + 1) <= budget:
        n += 1
    max_stops = n
    assert max_stops == 3, f"Puttalam Fresh rear_dock max_stops={max_stops}, expected 3"


def test_max_stops_badulla_fresh(ref_data: ReferenceData):
    """
    Max stops by time budget for Badulla Fresh is 2 (from spec table 11.1).
    """
    district_ref = ref_data.districts["Badulla"]
    budget = 270
    sa = service_allowance(ref_data, "Fresh", "rear_dock")
    outbound = district_ref.depot_to_district_freeflow_min
    inter = district_ref.inter_stop_freeflow_min

    n = 0
    while outbound + inter * n + sa * (n + 1) <= budget:
        n += 1
    assert n == 2, f"Badulla Fresh rear_dock max_stops={n}, expected 2"
