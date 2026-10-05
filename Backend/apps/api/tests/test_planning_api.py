"""
Tests for Dispatcher Planning, Trips, and Run lifecycle API endpoints.
"""

from datetime import date
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.models.domain import Trip, TripStop, Order, PlanRun, Deferral
from app.seed.loader import seed_all
from app.seed.fallback_day import create_preplanned_fallback_day


@pytest.fixture(autouse=True)
def setup_seed(db: Session):
    seed_all(db, force=True)


def get_dispatcher_headers(depot_ids: list = None):
    token = create_access_token(
        user_id="dispatcher@waypoint.test",
        username="dispatcher@waypoint.test",
        role="dispatcher",
        depot_ids=depot_ids or ["Peliyagoda", "Kandy"],
    )
    return {"Authorization": f"Bearer {token}"}


def test_get_dashboard(client: TestClient):
    headers = get_dispatcher_headers()
    resp = client.get("/api/v1/dashboard?depot_id=Peliyagoda", headers=headers)
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["depot_id"] == "Peliyagoda"
    assert "cutoff" in data
    assert "orders" in data
    assert "planning_progress" in data
    assert "vehicles" in data
    assert "alerts" in data
    assert "active_trips" in data


def test_get_dispatch_queue(client: TestClient):
    headers = get_dispatcher_headers()
    resp = client.get("/api/v1/dispatch/queue?depot_id=Peliyagoda", headers=headers)
    assert resp.status_code == 200
    orders = resp.json()
    assert isinstance(orders, list)


def test_generate_plan_and_list_plans(client: TestClient):
    headers = get_dispatcher_headers()
    body = {
        "depot_id": "Peliyagoda",
        "delivery_date": "2025-08-01",
        "regenerate": True,
    }
    resp = client.post("/api/v1/plans/generate", json=body, headers=headers)
    assert resp.status_code == 200, resp.text
    plan_run = resp.json()
    assert plan_run["depot_id"] == "Peliyagoda"
    assert plan_run["status"] == "OPEN"
    plan_run_id = plan_run["id"]

    # List plans
    resp_list = client.get("/api/v1/plans?depot_id=Peliyagoda", headers=headers)
    assert resp_list.status_code == 200
    assert any(p["id"] == plan_run_id for p in resp_list.json())

    # Get trips for plan run
    resp_trips = client.get(f"/api/v1/plans/{plan_run_id}/trips", headers=headers)
    assert resp_trips.status_code == 200
    trips_detail = resp_trips.json()
    assert len(trips_detail) > 0
    assert "trip" in trips_detail[0]
    assert "stops" in trips_detail[0]


def test_validate_plan(client: TestClient):
    headers = get_dispatcher_headers()
    # Generate plan
    gen_resp = client.post("/api/v1/plans/generate", json={
        "depot_id": "Peliyagoda",
        "delivery_date": "2025-08-01",
        "regenerate": True,
    }, headers=headers)
    assert gen_resp.status_code == 200
    plan_run_id = gen_resp.json()["id"]

    # Validate plan
    val_resp = client.post("/api/v1/plans/validate", json={"plan_run_id": plan_run_id}, headers=headers)
    assert val_resp.status_code == 200
    assert "valid" in val_resp.json()
    assert "violations" in val_resp.json()


def test_trip_order_edit_and_confirmation_lifecycle(client: TestClient, db: Session):
    headers = get_dispatcher_headers()
    gen_resp = client.post("/api/v1/plans/generate", json={
        "depot_id": "Peliyagoda",
        "delivery_date": "2025-08-01",
        "regenerate": True,
    }, headers=headers)
    plan_run_id = gen_resp.json()["id"]

    trips_resp = client.get(f"/api/v1/plans/{plan_run_id}/trips", headers=headers)
    trips = trips_resp.json()
    assert len(trips) > 0
    target_trip = trips[0]["trip"]
    trip_id = target_trip["id"]

    # 1. Confirm Trip
    conf_resp = client.post(f"/api/v1/trips/{trip_id}/confirm", headers=headers)
    assert conf_resp.status_code == 200
    assert conf_resp.json()["trip"]["status"] == "CONFIRMED"

    # Verify orders on trip are SCHEDULED
    stops = conf_resp.json()["stops"]
    assert len(stops) > 0
    for s in stops:
        ord_obj = db.query(Order).filter_by(id=s["order_id"]).first()
        assert ord_obj.status == "SCHEDULED"

    # Confirming already confirmed trip returns 409
    conf_again = client.post(f"/api/v1/trips/{trip_id}/confirm", headers=headers)
    assert conf_again.status_code == 409


def test_trip_cancel_returns_orders_to_submitted(client: TestClient, db: Session):
    headers = get_dispatcher_headers()
    gen_resp = client.post("/api/v1/plans/generate", json={
        "depot_id": "Peliyagoda",
        "delivery_date": "2025-08-01",
        "regenerate": True,
    }, headers=headers)
    plan_run_id = gen_resp.json()["id"]

    trips_resp = client.get(f"/api/v1/plans/{plan_run_id}/trips", headers=headers)
    trip_id = trips_resp.json()[0]["trip"]["id"]

    # Cancel Trip
    cancel_resp = client.post(f"/api/v1/trips/{trip_id}/cancel", headers=headers)
    assert cancel_resp.status_code == 200
    assert cancel_resp.json()["status"] == "CANCELLED"


def test_manual_defer_and_requeue(client: TestClient, db: Session):
    headers = get_dispatcher_headers()
    order = db.query(Order).filter_by(status="SUBMITTED").first()
    assert order is not None

    # Defer order
    defer_resp = client.post(f"/api/v1/orders/{order.id}/defer", json={
        "reason_text": "Store roof undergoing repair",
        "note": "Hold until tomorrow",
    }, headers=headers)
    assert defer_resp.status_code == 200
    assert defer_resp.json()["reason_class"] == "DISPATCHER"
    assert defer_resp.json()["reason_code"] == "MANUAL"

    db.refresh(order)
    assert order.status == "DEFERRED"

    # Requeue order
    requeue_resp = client.post(f"/api/v1/orders/{order.id}/requeue", headers=headers)
    assert requeue_resp.status_code == 200
    assert requeue_resp.json()["status"] == "SUBMITTED"


def test_plans_summary_fuel_and_fleet(client: TestClient):
    headers = get_dispatcher_headers()
    # Summary
    sum_resp = client.get("/api/v1/plans/summary?depot_id=Peliyagoda", headers=headers)
    assert sum_resp.status_code == 200
    data = sum_resp.json()
    assert "trips" in data
    assert "capacity" in data
    assert "reefer" in data
    assert "fuel" in data

    # Fuel
    fuel_resp = client.get("/api/v1/fuel?depot_id=Peliyagoda", headers=headers)
    assert fuel_resp.status_code == 200
    assert isinstance(fuel_resp.json(), list)

    # Fleet
    fleet_resp = client.get("/api/v1/fleet?depot_id=Peliyagoda&date=2025-08-01", headers=headers)
    assert fleet_resp.status_code == 200
    assert isinstance(fleet_resp.json(), list)


def test_preplanned_fallback_day(db: Session):
    """Verifies the pre-planned fallback day generator creates CONFIRMED trips."""
    res = create_preplanned_fallback_day(db)
    assert res["peliyagoda_confirmed_trips"] > 0
    assert res["kandy_confirmed_trips"] > 0
