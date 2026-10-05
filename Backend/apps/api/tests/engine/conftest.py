"""
conftest.py – fixtures built from the real CSVs, no hard-coded values.

All reference data values come from reading the CSVs at the time the fixture runs.
The paths are resolved relative to the repo root.
"""

import csv
import os
import pytest

from app.engine.types import DistrictRef, OutletRef, ReferenceData, VehicleRef


def _csv_path(filename: str) -> str:
    """Find the CSV in the Backend/db/seed/data directory."""
    candidates = [
        os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "db", "seed", "data", filename),
        os.path.join(os.path.dirname(__file__), "..", "..", "..", "db", "seed", "data", filename),
    ]
    for path in candidates:
        path = os.path.abspath(path)
        if os.path.exists(path):
            return path
    raise FileNotFoundError(f"Could not find {filename}")


@pytest.fixture(scope="session")
def ref_data() -> ReferenceData:
    """Load all reference CSVs once per test session."""

    # districts
    districts = {}
    with open(_csv_path("district_travel.csv"), newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            districts[row["district"]] = DistrictRef(
                district=row["district"],
                depot=row["depot"],
                depot_to_district_km=float(row["depot_to_district_km"]),
                depot_to_district_freeflow_min=int(row["depot_to_district_freeflow_min"]),
                inter_stop_km=float(row["inter_stop_km"]),
                inter_stop_freeflow_min=int(row["inter_stop_freeflow_min"]),
            )

    # outlets
    outlets = {}
    with open(_csv_path("outlets.csv"), newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            outlets[row["outlet_id"]] = OutletRef(
                outlet_id=row["outlet_id"],
                brand=row["brand"],
                district=row["district"],
                depot=row["depot"],
                dock_type=row["dock_type"],
                parking_constraint=row["parking_constraint"],
                window_open_time=row["window_open_time"],
                window_close_time=row["window_close_time"],
            )

    # vehicles
    vehicles = {}
    with open(_csv_path("vehicles.csv"), newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            vehicles[row["vehicle_id"]] = VehicleRef(
                vehicle_id=row["vehicle_id"],
                type=row["type"],
                temp=row["temp"],
                weight_cap_kg=float(row["weight_cap_kg"]),
                volume_cap_m3=float(row["volume_cap_m3"]),
                km_per_l=float(row["km_per_l"]),
                weekly_fuel_quota_l=float(row["weekly_fuel_quota_l"]),
                depot=row["depot"],
            )

    # service allowance
    service_allowance = {}
    with open(_csv_path("service_allowance.csv"), newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            service_allowance[(row["brand"], row["dock_type"])] = int(row["service_allowance_min"])

    return ReferenceData(
        districts=districts,
        outlets=outlets,
        vehicles=vehicles,
        service_allowance=service_allowance,
    )
