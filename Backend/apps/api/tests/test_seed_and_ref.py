import pytest
from app.seed.loader import seed_reference_data
from app.models.domain import (
    Depot,
    District,
    Outlet,
    Vehicle,
    ServiceAllowance,
    CalendarDay,
    User,
)

def test_seed_counts_and_data_integrity(db):
    """Verifies all reference data counts and specific business invariants from CSVs."""
    counts = seed_reference_data(db, force=True)
    
    assert counts["outlets"] == 120
    assert counts["vehicles"] == 60
    assert counts["calendar_days"] == 910
    assert counts["districts"] == 12
    assert counts["service_allowance"] == 9
    
    # Outlets count by brand: Fresh 80, Style 25, Tech 15
    fresh_count = db.query(Outlet).filter(Outlet.brand == "Fresh").count()
    style_count = db.query(Outlet).filter(Outlet.brand == "Style").count()
    tech_count = db.query(Outlet).filter(Outlet.brand == "Tech").count()
    
    assert fresh_count == 80
    assert style_count == 25
    assert tech_count == 15
    
    # 16 chilled-capable (reefer) vehicles
    chilled_count = db.query(Vehicle).filter(Vehicle.temp.in_(["reefer", "chilled"])).count()
    assert chilled_count == 16
    
    # 13 van_only outlets
    van_only_count = db.query(Outlet).filter(Outlet.parking_constraint == "van_only").count()
    assert van_only_count == 13
    
    # 12 mall outlets whose window_open_time & window_close_time equal mall_window bounds
    mall_outlets = db.query(Outlet).filter(Outlet.parking_constraint == "mall_dock").all()
    assert len(mall_outlets) == 12
    for mo in mall_outlets:
        assert mo.mall_window is not None
        open_t, close_t = mo.mall_window.split("-")
        assert mo.window_open_time == open_t
        assert mo.window_close_time == close_t
        
    # Every outlet's depot_id matches its district's depot_id
    districts_map = {d.id: d.depot_id for d in db.query(District).all()}
    outlets = db.query(Outlet).all()
    for o in outlets:
        assert o.depot_id == districts_map[o.district]
        
    # Deterministic display name check (e.g. Fresh Colombo 01)
    fresh_colombo_1 = db.query(Outlet).filter(Outlet.id == "OUT001").first()
    assert fresh_colombo_1 is not None
    assert "Fresh" in fresh_colombo_1.display_name
    assert "Colombo" in fresh_colombo_1.display_name
    
    # Users check: 60 drivers + 120 store managers + headline accounts
    drivers_count = db.query(User).filter(User.role == "driver").count()
    store_mgr_count = db.query(User).filter(User.role == "store_manager").count()
    headline_disp = db.query(User).filter(User.username == "dispatcher@waypoint.test").first()
    headline_load = db.query(User).filter(User.username == "loader@waypoint.test").first()
    
    assert drivers_count >= 60
    assert store_mgr_count >= 120
    assert headline_disp is not None
    assert headline_load is not None

def test_seed_idempotency(db):
    """Verifies that running seed twice creates no duplicate records."""
    counts_first = seed_reference_data(db, force=True)
    counts_second = seed_reference_data(db, force=False)
    
    assert counts_first == counts_second
    assert db.query(Outlet).count() == 120
    assert db.query(Vehicle).count() == 60
    assert db.query(CalendarDay).count() == 910

def test_ref_endpoints_auth_and_responses(client, db):
    """Verifies authentication and response structures for GET /ref/* endpoints."""
    seed_reference_data(db, force=True)
    
    # Unauthenticated calls return 401
    assert client.get("/api/v1/ref/outlets").status_code == 401
    assert client.get("/api/v1/ref/vehicles").status_code == 401
    assert client.get("/api/v1/ref/calendar").status_code == 401
    assert client.get("/api/v1/ref/config").status_code == 401
    
    # Login as dispatcher
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "dispatcher@waypoint.test", "password": "pass123"}
    )
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # GET /ref/outlets
    res_outlets = client.get("/api/v1/ref/outlets", headers=headers)
    assert res_outlets.status_code == 200
    outlets_data = res_outlets.json()
    assert len(outlets_data) == 120
    assert "outlet_id" in outlets_data[0]
    assert "depot" in outlets_data[0]
    assert "display_name" in outlets_data[0]
    
    # GET /ref/vehicles
    res_vehicles = client.get("/api/v1/ref/vehicles", headers=headers)
    assert res_vehicles.status_code == 200
    vehicles_data = res_vehicles.json()
    assert len(vehicles_data) == 60
    assert "vehicle_id" in vehicles_data[0]
    assert "depot" in vehicles_data[0]
    assert "weight_cap_kg" in vehicles_data[0]
    
    # GET /ref/calendar
    res_cal = client.get("/api/v1/ref/calendar", headers=headers)
    assert res_cal.status_code == 200
    cal_data = res_cal.json()
    assert len(cal_data) == 910
    assert "date" in cal_data[0]
    assert "is_operating" in cal_data[0]
    assert isinstance(cal_data[0]["is_operating"], int)
    
    # GET /ref/config
    res_cfg = client.get("/api/v1/ref/config", headers=headers)
    assert res_cfg.status_code == 200
    cfg_data = res_cfg.json()
    assert cfg_data["cutoff_time"] == "16:00"
    assert cfg_data["budget_fresh_min"] == 270
    assert cfg_data["budget_style_tech_min"] == 480
    assert cfg_data["unit_constants"] is None
