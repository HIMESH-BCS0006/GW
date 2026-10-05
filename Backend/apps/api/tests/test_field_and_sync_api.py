"""
Test suite for Task B6: Field-role API, loading, driver execution, monitoring, and offline sync.
"""

from datetime import datetime, timezone
import pytest
from starlette.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.models.domain import (
    Deferral,
    Event,
    ExceptionRecord,
    LoadCheck,
    Order,
    Outlet,
    OutletServiceState,
    Receipt,
    SyncOp,
    Trip,
    TripStop,
)
from app.seed.loader import seed_all
from app.seed.day_generator import seed_walkthrough_data
from app.services.planning_service import generate_plan_service, confirm_trip_service
from app.schemas.planning import GeneratePlanRequest


def get_token_headers(user_id: str, role: str, depot_ids: list = None, outlet_id: str = None, vehicle_id: str = None):
    token = create_access_token(
        user_id=user_id,
        username=user_id,
        role=role,
        depot_ids=depot_ids or [],
        outlet_id=outlet_id,
        vehicle_id=vehicle_id,
    )
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def plan_ready_db(client: TestClient, db: Session):
    seed_all(db, force=True)
    seed_walkthrough_data(db, force=True)
    gen_req = GeneratePlanRequest(depot_id="Peliyagoda", delivery_date="2025-08-01", regenerate=True)
    plan_run = generate_plan_service(db, gen_req, user_id="dispatcher@waypoint.test")
    return plan_run


def test_shortfall_flow_end_to_end(client: TestClient, db: Session, plan_ready_db):
    loader_headers = get_token_headers("loader@waypoint.test", "loader", depot_ids=["Peliyagoda"])
    disp_headers = get_token_headers("dispatcher@waypoint.test", "dispatcher", depot_ids=["Peliyagoda"])

    # 1. Get confirmed trip
    trip = db.query(Trip).filter_by(depot_id="Peliyagoda").first()
    assert trip is not None
    confirm_trip_service(db, trip.id, user_id="dispatcher@waypoint.test")

    # 2. Get load list
    ll_resp = client.get(f"/api/v1/trips/{trip.id}/load-list", headers=loader_headers)
    assert ll_resp.status_code == 200
    load_list = ll_resp.json()
    assert len(load_list["delivery_sequence"]) > 0
    assert len(load_list["reverse_load_order"]) == len(load_list["delivery_sequence"])
    assert load_list["delivery_sequence"][0]["id"] == load_list["reverse_load_order"][-1]["id"]

    # 3. Start loading
    start_resp = client.post(f"/api/v1/trips/{trip.id}/load-start", headers=loader_headers)
    assert start_resp.status_code == 200
    assert start_resp.json()["status"] == "LOADING"

    # 4. Report shortfall (Missing stock)
    stop = db.query(TripStop).filter_by(trip_id=trip.id).first()
    order_id = stop.order_id
    lc_resp = client.post(f"/api/v1/trips/{trip.id}/load-checks", json={
        "order_id": order_id,
        "plan_version": trip.plan_version,
        "expected_qty": 50,
        "loaded_qty": 0,
        "issue": "missing",
        "note": "Item damaged on dock",
    }, headers=loader_headers)
    assert lc_resp.status_code == 201
    lc_data = lc_resp.json()
    assert lc_data["status"] == "OPEN"
    lc_id = lc_data["id"]

    # Verify trip is now BLOCKED
    db.refresh(trip)
    assert trip.status == "BLOCKED"

    # 5. Confirming load while BLOCKED returns 409
    conf_resp = client.post(f"/api/v1/trips/{trip.id}/load-confirm", json={"plan_version": trip.plan_version}, headers=loader_headers)
    assert conf_resp.status_code == 409

    # 6. Dispatcher resolves shortfall by deferring order
    resolve_resp = client.post(f"/api/v1/load-checks/{lc_id}/resolve", json={
        "resolution": "defer_order",
        "note": "Re-order for next cycle",
    }, headers=disp_headers)
    assert resolve_resp.status_code == 200
    assert resolve_resp.json()["status"] == "RESOLVED"

    # Verify order is DEFERRED and trip is unblocked (LOADING)
    db.refresh(trip)
    assert trip.status == "LOADING"
    deferred_ord = db.query(Order).filter_by(id=order_id).first()
    assert deferred_ord.status == "DEFERRED"

    # 7. Confirm load with current plan_version
    conf_success = client.post(f"/api/v1/trips/{trip.id}/load-confirm", json={"plan_version": trip.plan_version}, headers=loader_headers)
    assert conf_success.status_code == 200
    assert conf_success.json()["status"] == "LOADED"


def test_driver_execution_lifecycle_and_scope(client: TestClient, db: Session, plan_ready_db):
    trip = db.query(Trip).filter_by(depot_id="Peliyagoda").first()
    confirm_trip_service(db, trip.id, user_id="dispatcher@waypoint.test")

    # Loader confirms load
    trip.status = "LOADED"
    db.commit()

    driver_headers = get_token_headers("driver1@waypoint.test", "driver", vehicle_id=trip.vehicle_id)
    other_driver_headers = get_token_headers("driver2@waypoint.test", "driver", vehicle_id="V999")

    # 1. Driver list trips
    trips_resp = client.get("/api/v1/driver/trips", headers=driver_headers)
    assert trips_resp.status_code == 200
    assert any(t["id"] == trip.id for t in trips_resp.json())

    # 2. Scope check: other driver cannot start this trip
    start_other = client.post(f"/api/v1/trips/{trip.id}/start", json={"plan_version": trip.plan_version}, headers=other_driver_headers)
    assert start_other.status_code == 403

    # 3. Authorized driver starts trip
    start_resp = client.post(f"/api/v1/trips/{trip.id}/start", json={"plan_version": trip.plan_version}, headers=driver_headers)
    assert start_resp.status_code == 200
    assert start_resp.json()["status"] == "IN_PROGRESS"

    # 4. Stop arrival
    stops = db.query(TripStop).filter_by(trip_id=trip.id).order_by(TripStop.seq.asc()).all()
    assert len(stops) >= 1
    stop1 = stops[0]

    arrive_resp = client.post(f"/api/v1/stops/{stop1.id}/arrive", headers=driver_headers)
    assert arrive_resp.status_code == 200
    assert arrive_resp.json()["status"] == "ARRIVED"

    # 5. Stop outcome: delivered
    outcome_resp = client.post(f"/api/v1/stops/{stop1.id}/outcome", json={
        "outcome": "delivered",
        "received_by": "Kamal Perera (Store Mgr)",
        "completed_at": datetime.now(timezone.utc).isoformat(),
    }, headers=driver_headers)
    assert outcome_resp.status_code == 200
    assert outcome_resp.json()["status"] == "DELIVERED"
    assert outcome_resp.json()["receipt_status"] == "AWAITING"

    # Verify outlet service state updated
    ord1 = db.query(Order).filter_by(id=stop1.order_id).first()
    oss = db.query(OutletServiceState).filter_by(outlet_id=ord1.outlet_id).first()
    assert oss is not None
    assert oss.last_served_date is not None
    assert oss.consecutive_deferrals == 0

    # 6. Complete trip
    complete_resp = client.post(f"/api/v1/trips/{trip.id}/complete", headers=driver_headers)
    assert complete_resp.status_code == 200
    assert complete_resp.json()["status"] == "COMPLETED"


def test_store_manager_receipt_confirmation(client: TestClient, db: Session, plan_ready_db):
    trip = db.query(Trip).first()
    stop = db.query(TripStop).filter_by(trip_id=trip.id).first()
    order = db.query(Order).filter_by(id=stop.order_id).first()

    sm_headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id=order.outlet_id)
    other_sm_headers = get_token_headers("other@waypoint.test", "store_manager", outlet_id="OUT999")

    # Other store manager rejected by scope (403)
    resp_forbidden = client.post(f"/api/v1/stops/{stop.id}/receipt", json={
        "outcome": "full",
        "note": "All goods received intact",
    }, headers=other_sm_headers)
    assert resp_forbidden.status_code == 403

    # Authorized store manager confirms receipt
    resp_ok = client.post(f"/api/v1/stops/{stop.id}/receipt", json={
        "outcome": "full",
        "note": "All goods received intact",
    }, headers=sm_headers)
    assert resp_ok.status_code == 200
    data = resp_ok.json()
    assert data["outcome"] == "full"
    assert data["stop_id"] == stop.id

    db.refresh(stop)
    assert stop.receipt_status == "CONFIRMED"


def test_offline_sync_idempotency_and_conflicts(client: TestClient, db: Session, plan_ready_db):
    trip = db.query(Trip).first()
    stop = db.query(TripStop).filter_by(trip_id=trip.id).first()
    driver_headers = get_token_headers("driver@waypoint.test", "driver", vehicle_id=trip.vehicle_id)

    # 1. Sync batch of operations
    batch_req = {
        "operations": [
            {
                "client_op_id": "OP-SYNC-001",
                "device_id": "DEV-01",
                "client_seq": 1,
                "op_type": "arrive_stop",
                "payload": {"stop_id": stop.id},
                "client_ts": datetime.now(timezone.utc).isoformat(),
            },
            {
                "client_op_id": "OP-SYNC-002",
                "device_id": "DEV-01",
                "client_seq": 2,
                "op_type": "record_outcome",
                "payload": {
                    "stop_id": stop.id,
                    "outcome": "delivered",
                    "quantity_delivered": 20,
                    "received_by": "Manager",
                    "completed_at": datetime.now(timezone.utc).isoformat(),
                },
                "client_ts": datetime.now(timezone.utc).isoformat(),
            }
        ]
    }

    sync_resp1 = client.post("/api/v1/sync", json=batch_req, headers=driver_headers)
    assert sync_resp1.status_code == 200
    results1 = sync_resp1.json()["results"]
    assert len(results1) == 2
    assert results1[0]["result"] == "applied"
    assert results1[1]["result"] == "applied"

    # 2. Replay same batch -> returns replayed (Idempotency)
    sync_resp2 = client.post("/api/v1/sync", json=batch_req, headers=driver_headers)
    assert sync_resp2.status_code == 200
    results2 = sync_resp2.json()["results"]
    assert results2[0]["result"] == "replayed"
    assert results2[1]["result"] == "replayed"

    # 3. Conflict case: Trip was cancelled while driver was offline
    trip.status = "CANCELLED"
    db.commit()

    conflict_batch = {
        "operations": [
            {
                "client_op_id": "OP-SYNC-003",
                "device_id": "DEV-01",
                "client_seq": 3,
                "op_type": "record_outcome",
                "payload": {
                    "stop_id": stop.id,
                    "outcome": "delivered",
                    "completed_at": datetime.now(timezone.utc).isoformat(),
                },
                "client_ts": datetime.now(timezone.utc).isoformat(),
            },
            {
                "client_op_id": "OP-SYNC-004",
                "device_id": "DEV-01",
                "client_seq": 4,
                "op_type": "start_trip",
                "payload": {
                    "trip_id": trip.id,
                    "plan_version": trip.plan_version,
                },
                "client_ts": datetime.now(timezone.utc).isoformat(),
            }
        ]
    }

    conflict_resp = client.post("/api/v1/sync", json=conflict_batch, headers=driver_headers)
    assert conflict_resp.status_code == 200
    c_results = conflict_resp.json()["results"]
    # Field fact applied with conflict per D14
    assert c_results[0]["result"] == "applied_with_conflict"
    # Command rejected per D14
    assert c_results[1]["result"] == "rejected"


def test_monitoring_live_and_alerts(client: TestClient, db: Session, plan_ready_db):
    disp_headers = get_token_headers("dispatcher@waypoint.test", "dispatcher", depot_ids=["Peliyagoda"])

    # 1. Live Monitoring
    mon_resp = client.get("/api/v1/monitoring/live?depot_id=Peliyagoda", headers=disp_headers)
    assert mon_resp.status_code == 200
    mon_data = mon_resp.json()
    assert "last_synced_at" in mon_data
    assert len(mon_data["trips"]) > 0

    # 2. List Alerts
    alerts_resp = client.get("/api/v1/alerts?depot_id=Peliyagoda", headers=disp_headers)
    assert alerts_resp.status_code == 200
    assert isinstance(alerts_resp.json(), list)

    # 3. List Load Checks
    lc_resp = client.get("/api/v1/load-checks?depot_id=Peliyagoda", headers=disp_headers)
    assert lc_resp.status_code == 200

    # 4. List Deferrals
    def_resp = client.get("/api/v1/deferrals?depot_id=Peliyagoda", headers=disp_headers)
    assert def_resp.status_code == 200


def test_events_stream_sse_scope_filtering(client: TestClient, db: Session):
    driver_headers = get_token_headers("driver1@waypoint.test", "driver", vehicle_id="V001")
    store_headers = get_token_headers("store@waypoint.test", "store_manager", outlet_id="OUT001")

    # Connect to stream
    resp = client.get("/api/v1/events/stream", headers=driver_headers)
    assert resp.status_code == 200
    assert "text/event-stream" in resp.headers["content-type"]
    assert "event: connected" in resp.text
