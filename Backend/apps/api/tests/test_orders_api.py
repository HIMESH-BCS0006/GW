"""
Tests for Store Manager / Orders API endpoints.
"""

from datetime import date
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.models.domain import Order, Outlet, CalendarDay
from app.seed.loader import seed_all


@pytest.fixture(autouse=True)
def setup_seed(db: Session):
    seed_all(db, force=True)


def get_token_headers(user_id: str, role: str, outlet_id: str = None, depot_ids: list = None):
    token = create_access_token(
        user_id=user_id,
        username=user_id,
        role=role,
        outlet_id=outlet_id,
        depot_ids=depot_ids or ["Peliyagoda"],
    )
    return {"Authorization": f"Bearer {token}"}


def test_post_orders_derives_weight_and_volume(client: TestClient):
    headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT004")
    body = {
        "outlet_id": "OUT004",
        "delivery_date": "2025-08-01",
        "temp_requirement": "ambient",
        "order_units": 100,
        "note": "Fresh vegetables delivery",
    }
    resp = client.post("/api/v1/orders", json=body, headers=headers)
    assert resp.status_code == 201, resp.text
    data = resp.json()
    assert data["order"]["outlet_id"] == "OUT004"
    assert data["order"]["status"] == "SUBMITTED"
    assert data["order"]["order_weight_kg"] == 250.0  # 100 units * 2.5 kg
    assert data["order"]["order_volume_m3"] == 1.2    # 100 units * 0.012 m3
    assert data["rolled_over"] is False
    assert "confirmation_code" in data


def test_post_orders_manual_weight_and_volume(client: TestClient):
    headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT004")
    body = {
        "outlet_id": "OUT004",
        "delivery_date": "2025-08-01",
        "temp_requirement": "chilled",
        "order_units": 50,
        "order_weight_kg": 450.0,
        "order_volume_m3": 2.5,
    }
    resp = client.post("/api/v1/orders", json=body, headers=headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["order"]["order_weight_kg"] == 450.0
    assert data["order"]["order_volume_m3"] == 2.5
    assert data["order"]["temp_requirement"] == "chilled"


def test_post_orders_chilled_on_non_fresh_fails(client: TestClient):
    # OUT048 is a Style outlet
    headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT048")
    body = {
        "outlet_id": "OUT048",
        "delivery_date": "2025-08-01",
        "temp_requirement": "chilled",
        "order_units": 20,
    }
    resp = client.post("/api/v1/orders", json=body, headers=headers)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "VALIDATION_ERROR"


def test_post_orders_non_operating_day_fails(client: TestClient):
    # 2025-08-03 is Sunday (non-operating)
    headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT004")
    body = {
        "outlet_id": "OUT004",
        "delivery_date": "2025-08-03",
        "temp_requirement": "ambient",
        "order_units": 10,
    }
    resp = client.post("/api/v1/orders", json=body, headers=headers)
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == "NOT_OPERATING_DAY"


def test_post_orders_idempotency(client: TestClient):
    headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT004")
    body = {
        "outlet_id": "OUT004",
        "delivery_date": "2025-08-01",
        "temp_requirement": "ambient",
        "order_units": 80,
        "client_op_id": "OP-UUID-99999",
    }
    resp1 = client.post("/api/v1/orders", json=body, headers=headers)
    assert resp1.status_code == 201
    ord_id = resp1.json()["order"]["id"]

    # Replay same client_op_id
    resp2 = client.post("/api/v1/orders", json=body, headers=headers)
    assert resp2.status_code == 201
    assert resp2.json()["order"]["id"] == ord_id


def test_get_orders_list_and_detail(client: TestClient):
    headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT004")
    resp = client.get("/api/v1/orders", headers=headers)
    assert resp.status_code == 200
    orders = resp.json()
    assert isinstance(orders, list)
    assert len(orders) > 0

    order_id = orders[0]["id"]
    resp_detail = client.get(f"/api/v1/orders/{order_id}", headers=headers)
    assert resp_detail.status_code == 200
    assert resp_detail.json()["id"] == order_id


def test_cancel_order_lifecycle(client: TestClient):
    headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT004")
    # 1. Create order
    create_resp = client.post("/api/v1/orders", json={
        "outlet_id": "OUT004",
        "delivery_date": "2025-08-01",
        "temp_requirement": "ambient",
        "order_units": 30,
    }, headers=headers)
    assert create_resp.status_code == 201
    ord_id = create_resp.json()["order"]["id"]

    # 2. Cancel order
    cancel_resp = client.post(f"/api/v1/orders/{ord_id}/cancel", json={
        "reason": "Overstocked inventory",
        "note": "Manager requested cancellation",
    }, headers=headers)
    assert cancel_resp.status_code == 200
    assert cancel_resp.json()["status"] == "CANCELLED"
    assert cancel_resp.json()["cancel_reason"] == "Overstocked inventory"

    # 3. Cancelling again returns 409
    cancel_again = client.post(f"/api/v1/orders/{ord_id}/cancel", json={"reason": "Repeat"}, headers=headers)
    assert cancel_again.status_code == 409


def test_expected_deliveries_and_notifications(client: TestClient):
    headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT004")
    exp_resp = client.get("/api/v1/outlets/OUT004/expected-deliveries", headers=headers)
    assert exp_resp.status_code == 200
    assert isinstance(exp_resp.json(), list)

    notif_resp = client.get("/api/v1/notifications", headers=headers)
    assert notif_resp.status_code == 200
    notifs = notif_resp.json()
    assert isinstance(notifs, list)

    if notifs:
        n_id = notifs[0]["id"]
        read_resp = client.post(f"/api/v1/notifications/{n_id}/read", headers=headers)
        assert read_resp.status_code == 200
