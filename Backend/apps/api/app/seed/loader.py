import os
import csv
from datetime import datetime
from typing import Dict, Tuple
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.config import settings
from app.core.security import hash_password
from app.models.domain import (
    Depot,
    District,
    Outlet,
    Vehicle,
    ServiceAllowance,
    CalendarDay,
    RoadCondition,
    TrafficSpeed,
    User,
    UserDepotAccess,
    VehicleAvailability,
)

SEED_PASSWORD = os.getenv("SEED_PASSWORD", "pass123")

def find_seed_data_dir() -> str:
    """Finds seed data directory in relative paths."""
    env_dir = os.getenv("SEED_DATA_DIR")
    if env_dir and os.path.exists(env_dir) and os.path.exists(os.path.join(env_dir, "outlets.csv")):
        return os.path.abspath(env_dir)

    candidates = [
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "db", "seed", "data")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "db", "seed", "data")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "db", "seed", "data")),
        os.path.abspath("db/seed/data"),
        os.path.abspath("Backend/db/seed/data"),
        os.path.abspath("Backend/apps/api/db/seed/data"),
        os.path.abspath("/app/db/seed/data"),
        os.path.abspath("/app/Backend/db/seed/data"),
        os.path.abspath("../db/seed/data"),
        os.path.abspath("../../db/seed/data"),
    ]
    for path in candidates:
        if os.path.exists(path) and os.path.exists(os.path.join(path, "outlets.csv")):
            return path
    raise FileNotFoundError(f"Seed data directory containing outlets.csv not found in candidates: {candidates}")

def generate_outlet_display_names(outlets_csv_path: str) -> Dict[str, str]:
    """
    Generates deterministic display names per D23 (e.g. 'Fresh Colombo 01', 'Fresh Colombo 02').
    Grouped by (brand, district) in order of appearance in outlets.csv.
    """
    counts: Dict[Tuple[str, str], int] = {}
    display_names: Dict[str, str] = {}

    with open(outlets_csv_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            outlet_id = row["outlet_id"].strip()
            brand = row["brand"].strip()
            district = row["district"].strip()
            key = (brand, district)

            current_count = counts.get(key, 0) + 1
            counts[key] = current_count
            display_names[outlet_id] = f"{brand} {district} {current_count:02d}"

    return display_names

def seed_reference_data(db: Session, force: bool = False) -> Dict[str, int]:
    """
    Loads all reference CSVs into database idempotently.
    Returns counts of seeded entities.
    """
    # Idempotency check
    if not force and db.query(Outlet).count() >= 120 and db.query(Vehicle).count() >= 60:
        print("[SEED] Reference data already seeded. Skipping.")
        return {
            "depots": db.query(Depot).count(),
            "districts": db.query(District).count(),
            "outlets": db.query(Outlet).count(),
            "vehicles": db.query(Vehicle).count(),
            "service_allowance": db.query(ServiceAllowance).count(),
            "calendar_days": db.query(CalendarDay).count(),
            "users": db.query(User).count(),
        }

    data_dir = find_seed_data_dir()
    print(f"[SEED] Seeding reference data from: {data_dir}")

    # 1. Seed Depots
    depot_names = {
        "Peliyagoda": "Peliyagoda Distribution Center",
        "Kandy": "Kandy Regional Hub",
    }
    for d_id, d_name in depot_names.items():
        if not db.query(Depot).filter(Depot.id == d_id).first():
            db.add(Depot(id=d_id, name=d_name))
    db.commit()

    # 2. Seed Districts (district_travel.csv)
    dt_path = os.path.join(data_dir, "district_travel.csv")
    with open(dt_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            dist_id = row["district"].strip()
            if not db.query(District).filter(District.id == dist_id).first():
                db.add(District(
                    id=dist_id,
                    depot_id=row["depot"].strip(),
                    road_class=row["road_class"].strip(),
                    free_flow_kmh=int(float(row["free_flow_kmh"])),
                    depot_to_district_km=float(row["depot_to_district_km"]),
                    depot_to_district_freeflow_min=int(row["depot_to_district_freeflow_min"]),
                    inter_stop_km=float(row["inter_stop_km"]),
                    inter_stop_freeflow_min=int(row["inter_stop_freeflow_min"])
                ))
    db.commit()

    # 3. Seed Outlets (outlets.csv with deterministic display_name D23)
    outlets_path = os.path.join(data_dir, "outlets.csv")
    display_names = generate_outlet_display_names(outlets_path)

    with open(outlets_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            o_id = row["outlet_id"].strip()
            mall_win = row["mall_window"].strip() if row.get("mall_window") else None
            existing = db.query(Outlet).filter(Outlet.id == o_id).first()
            if existing:
                if force:
                    existing.brand = row["brand"].strip()
                    existing.district = row["district"].strip()
                    existing.depot_id = row["depot"].strip()
                    existing.dock_type = row["dock_type"].strip()
                    existing.parking_constraint = row["parking_constraint"].strip()
                    existing.mall_window = mall_win
                    existing.window_open_time = row["window_open_time"].strip()
                    existing.window_close_time = row["window_close_time"].strip()
                    existing.display_name = display_names.get(o_id, o_id)
            else:
                db.add(Outlet(
                    id=o_id,
                    brand=row["brand"].strip(),
                    district=row["district"].strip(),
                    depot_id=row["depot"].strip(),
                    dock_type=row["dock_type"].strip(),
                    parking_constraint=row["parking_constraint"].strip(),
                    mall_window=mall_win,
                    window_open_time=row["window_open_time"].strip(),
                    window_close_time=row["window_close_time"].strip(),
                    display_name=display_names.get(o_id, o_id)
                ))
    db.commit()

    # 4. Seed Vehicles (vehicles.csv)
    veh_path = os.path.join(data_dir, "vehicles.csv")
    with open(veh_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            v_id = row["vehicle_id"].strip()
            existing = db.query(Vehicle).filter(Vehicle.id == v_id).first()
            if existing:
                if force:
                    existing.type = row["type"].strip()
                    existing.temp = row["temp"].strip()
                    existing.weight_cap_kg = float(row["weight_cap_kg"])
                    existing.volume_cap_m3 = float(row["volume_cap_m3"])
                    existing.fuel_type = row["fuel_type"].strip()
                    existing.km_per_l = float(row["km_per_l"])
                    existing.weekly_fuel_quota_l = float(row["weekly_fuel_quota_l"])
                    existing.depot_id = row["depot"].strip()
            else:
                db.add(Vehicle(
                    id=v_id,
                    type=row["type"].strip(),
                    temp=row["temp"].strip(),
                    weight_cap_kg=float(row["weight_cap_kg"]),
                    volume_cap_m3=float(row["volume_cap_m3"]),
                    fuel_type=row["fuel_type"].strip(),
                    km_per_l=float(row["km_per_l"]),
                    weekly_fuel_quota_l=float(row["weekly_fuel_quota_l"]),
                    depot_id=row["depot"].strip()
                ))
    db.commit()

    # 5. Seed Service Allowance (service_allowance.csv - 9 rows)
    sa_path = os.path.join(data_dir, "service_allowance.csv")
    if db.query(ServiceAllowance).count() == 0:
        with open(sa_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                db.add(ServiceAllowance(
                    brand=row["brand"].strip(),
                    dock_type=row["dock_type"].strip(),
                    service_allowance_min=int(row["service_allowance_min"])
                ))
        db.commit()

    # 6. Seed Calendar Days (calendar.csv - 910 rows)
    cal_path = os.path.join(data_dir, "calendar.csv")
    if db.query(CalendarDay).count() == 0:
        with open(cal_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                dt = datetime.strptime(row["date"].strip(), "%Y-%m-%d").date()
                fest = row["festival"].strip() if row.get("festival") else None
                db.add(CalendarDay(
                    date=dt,
                    dow=int(row["dow"]),
                    dow_name=row["dow_name"].strip(),
                    is_weekend=bool(int(row["is_weekend"])),
                    iso_year=int(row["iso_year"]),
                    iso_week=int(row["iso_week"]),
                    is_payday=bool(int(row["is_payday"])),
                    festival=fest,
                    festival_ramp=float(row["festival_ramp"]),
                    is_holiday=bool(int(row["is_holiday"])),
                    monsoon=int(row["monsoon"]),
                    is_operating=bool(int(row["is_operating"]))
                ))
        db.commit()

    # 7. Seed Road Conditions (road_conditions.csv)
    rc_path = os.path.join(data_dir, "road_conditions.csv")
    if db.query(RoadCondition).count() == 0 and os.path.exists(rc_path):
        with open(rc_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            rc_list = []
            for row in reader:
                dt = datetime.strptime(row["date"].strip(), "%Y-%m-%d").date()
                rc_list.append(RoadCondition(
                    district=row["district"].strip(),
                    date=dt,
                    disruption_index=float(row["disruption_index"])
                ))
            db.bulk_save_objects(rc_list)
        db.commit()

    # 8. Seed Traffic Speed (traffic_speed.csv)
    ts_path = os.path.join(data_dir, "traffic_speed.csv")
    if db.query(TrafficSpeed).count() == 0 and os.path.exists(ts_path):
        with open(ts_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            ts_list = []
            for row in reader:
                ts_list.append(TrafficSpeed(
                    district=row["district"].strip(),
                    hour=int(row["hour"]),
                    monsoon=bool(int(row["monsoon"])),
                    speed_index=float(row["speed_index"])
                ))
            db.bulk_save_objects(ts_list)
        db.commit()

    # 9. Seed Users (60 drivers, 120 store managers, 4 headline accounts)
    pwd_hash = hash_password(SEED_PASSWORD)

    # Headline Accounts (.com and .test)
    headline_accounts = [
        {
            "id": "dispatcher@waypoint.com",
            "username": "dispatcher@waypoint.com",
            "role": "dispatcher",
            "display_name": "Dispatcher",
            "depot_access": ["Peliyagoda", "Kandy"],
        },
        {
            "id": "dispatcher@waypoint.test",
            "username": "dispatcher@waypoint.test",
            "role": "dispatcher",
            "display_name": "Dispatcher",
            "depot_access": ["Peliyagoda", "Kandy"],
        },
        {
            "id": "loader@waypoint.com",
            "username": "loader@waypoint.com",
            "role": "loader",
            "display_name": "Loader",
            "depot_access": ["Peliyagoda", "Kandy"],
        },
        {
            "id": "loader@waypoint.test",
            "username": "loader@waypoint.test",
            "role": "loader",
            "display_name": "Loader",
            "depot_access": ["Peliyagoda", "Kandy"],
        },
        {
            "id": "driver@waypoint.com",
            "username": "driver@waypoint.com",
            "role": "driver",
            "vehicle_id": "VEH001",
            "display_name": "Driver (VEH001)",
        },
        {
            "id": "driver@waypoint.test",
            "username": "driver@waypoint.test",
            "role": "driver",
            "vehicle_id": "VEH001",
            "display_name": "Driver (VEH001)",
        },
        {
            "id": "storemanager@waypoint.com",
            "username": "storemanager@waypoint.com",
            "role": "store_manager",
            "outlet_id": "OUT004",
            "display_name": "Store Manager (OUT004)",
        },
        {
            "id": "store_manager@waypoint.com",
            "username": "store_manager@waypoint.com",
            "role": "store_manager",
            "outlet_id": "OUT004",
            "display_name": "Store Manager (OUT004)",
        },
        {
            "id": "store@waypoint.com",
            "username": "store@waypoint.com",
            "role": "store_manager",
            "outlet_id": "OUT004",
            "display_name": "Store Manager (OUT004)",
        },
        {
            "id": "store@waypoint.test",
            "username": "store@waypoint.test",
            "role": "store_manager",
            "outlet_id": "OUT004",
            "display_name": "Store Manager (OUT004)",
        },
    ]

    for acc in headline_accounts:
        existing = db.query(User).filter(
            (User.id == acc["id"]) | (User.username == acc["username"])
        ).first()
        if not existing:
            db.add(User(
                id=acc["id"],
                username=acc["username"],
                password_hash=pwd_hash,
                role=acc["role"],
                outlet_id=acc.get("outlet_id"),
                vehicle_id=acc.get("vehicle_id"),
                display_name=acc["display_name"]
            ))
            db.flush()
            if "depot_access" in acc:
                for d_id in acc["depot_access"]:
                    if not db.query(UserDepotAccess).filter_by(user_id=acc["id"], depot_id=d_id).first():
                        db.add(UserDepotAccess(user_id=acc["id"], depot_id=d_id))
    db.commit()

    # 60 Driver Users (one per vehicle)
    vehicles = db.query(Vehicle).all()
    for v in vehicles:
        u_id = f"USR-DRV-{v.id}"
        u_name = f"driver_{v.id}@waypoint.test"
        existing = db.query(User).filter(
            (User.id == u_id) | (User.username == u_name)
        ).first()
        if not existing:
            db.add(User(
                id=u_id,
                username=u_name,
                password_hash=pwd_hash,
                role="driver",
                vehicle_id=v.id,
                display_name=f"Driver ({v.id})"
            ))
    db.commit()

    # 120 Store Manager Users (one per outlet)
    outlets = db.query(Outlet).all()
    for o in outlets:
        u_id = f"USR-STORE-{o.id}"
        u_name = f"store_{o.id}@waypoint.test"
        existing = db.query(User).filter(
            (User.id == u_id) | (User.username == u_name)
        ).first()
        if not existing:
            db.add(User(
                id=u_id,
                username=u_name,
                password_hash=pwd_hash,
                role="store_manager",
                outlet_id=o.id,
                display_name=f"Manager {o.display_name}"
            ))
    db.commit()

    # 10. Vehicle Availability defaults (all 60 vehicles available)
    # Seed default availability for Friday 2025-08-01 (seeded day D11)
    seeded_date = datetime.strptime("2025-08-01", "%Y-%m-%d").date()
    for v in vehicles:
        if not db.query(VehicleAvailability).filter_by(vehicle_id=v.id, date=seeded_date).first():
            db.add(VehicleAvailability(
                vehicle_id=v.id,
                date=seeded_date,
                status="available",
                note="Default available"
            ))
    db.commit()

    counts = {
        "depots": db.query(Depot).count(),
        "districts": db.query(District).count(),
        "outlets": db.query(Outlet).count(),
        "vehicles": db.query(Vehicle).count(),
        "service_allowance": db.query(ServiceAllowance).count(),
        "calendar_days": db.query(CalendarDay).count(),
        "users": db.query(User).count(),
    }
    print(f"[SEED] Successfully seeded reference data: {counts}")
    return counts


def seed_all(db: Session, force: bool = False) -> dict:
    """Seeds both reference data and walkthrough delivery day data."""
    from app.seed.day_generator import seed_walkthrough_data
    ref_counts = seed_reference_data(db, force=force)
    day_counts = seed_walkthrough_data(db, force=force)
    return {"reference": ref_counts, "walkthrough_day": day_counts}


def run_seed_cli():
    """CLI entrypoint for running seed job."""
    db = SessionLocal()
    try:
        seed_all(db)
    finally:
        db.close()


if __name__ == "__main__":
    run_seed_cli()
