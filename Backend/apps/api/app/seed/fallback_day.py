"""
fallback_day.py – seeds a pre-planned fallback day where trips are already CONFIRMED
and orders SCHEDULED so that the walkthrough can immediately proceed to loading/driving.
"""

from datetime import date
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.domain import PlanRun, Trip, TripStop, Order
from app.schemas.planning import GeneratePlanRequest
from app.seed.loader import seed_all
from app.services.planning_service import generate_plan_service, confirm_trip_service


def create_preplanned_fallback_day(db: Session) -> dict:
    """
    Seeds the reference & walkthrough day, generates plan runs for Peliyagoda and Kandy,
    and confirms all valid trips so the walkthrough has ready-to-load confirmed trips.
    """
    seed_res = seed_all(db, force=True)
    delivery_date = date(2025, 8, 1)

    # 1. Generate and confirm Peliyagoda plan
    pel_req = GeneratePlanRequest(depot_id="Peliyagoda", delivery_date=delivery_date, regenerate=True)
    pel_run = generate_plan_service(db, pel_req, user_id="dispatcher@waypoint.test")

    pel_trips = db.query(Trip).filter_by(plan_run_id=pel_run.id, status="DRAFT").all()
    confirmed_pel = 0
    for t in pel_trips:
        try:
            confirm_trip_service(db, trip_id=t.id, user_id="dispatcher@waypoint.test")
            confirmed_pel += 1
        except Exception:
            pass

    # 2. Generate and confirm Kandy plan
    kan_req = GeneratePlanRequest(depot_id="Kandy", delivery_date=delivery_date, regenerate=True)
    kan_run = generate_plan_service(db, kan_req, user_id="dispatcher@waypoint.test")

    kan_trips = db.query(Trip).filter_by(plan_run_id=kan_run.id, status="DRAFT").all()
    confirmed_kan = 0
    for t in kan_trips:
        try:
            confirm_trip_service(db, trip_id=t.id, user_id="dispatcher@waypoint.test")
            confirmed_kan += 1
        except Exception:
            pass

    return {
        "peliyagoda_run_id": pel_run.id,
        "peliyagoda_confirmed_trips": confirmed_pel,
        "kandy_run_id": kan_run.id,
        "kandy_confirmed_trips": confirmed_kan,
    }


def run_fallback_cli():
    db = SessionLocal()
    try:
        res = create_preplanned_fallback_day(db)
        print(f"[FALLBACK] Pre-planned fallback day created: {res}")
    finally:
        db.close()


if __name__ == "__main__":
    run_fallback_cli()
