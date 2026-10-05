import os
import sys
import pytest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Set test environment
os.environ["DATABASE_URL"] = "sqlite:///./test_waypoint.db"
os.environ["DEMO_MODE"] = "true"
os.environ["DEMO_NOW"] = "2025-07-31T14:00:00+05:30"
os.environ["SECRET_KEY"] = "test_secret_key_12345"

from app.main import app
from app.core.database import Base, get_db
from app.core.security import hash_password
from app.models.domain import User, UserDepotAccess, Depot, Outlet, Vehicle

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_waypoint.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    
    try:
        # Seed test reference data
        depot1 = Depot(id="Peliyagoda", name="Peliyagoda Central DC")
        depot2 = Depot(id="Kandy", name="Kandy Regional Hub")
        session.add_all([depot1, depot2])
        
        outlet1 = Outlet(
            id="OUT001", brand="Fresh", district="Colombo", depot_id="Peliyagoda",
            dock_type="rear_dock", parking_constraint="normal", mall_window=None,
            window_open_time="03:00", window_close_time="08:00", display_name="Fresh Colombo 01"
        )
        session.add(outlet1)
        
        vehicle1 = Vehicle(
            id="VEH001", type="truck", temp="chilled", weight_cap_kg=3610.0,
            volume_cap_m3=19.4, fuel_type="diesel", km_per_l=4.4, weekly_fuel_quota_l=500.0,
            depot_id="Peliyagoda"
        )
        session.add(vehicle1)
        session.commit()
        
        # Seed test users for all 4 roles
        password_hash = hash_password("pass123")
        
        # Dispatcher with access to Peliyagoda & Kandy
        user_dispatcher = User(
            id="USR-DISP", username="dispatcher@waypoint.test",
            password_hash=password_hash, role="dispatcher", display_name="Test Dispatcher"
        )
        # Loader with access to Peliyagoda only
        user_loader = User(
            id="USR-LOAD", username="loader@waypoint.test",
            password_hash=password_hash, role="loader", display_name="Test Loader"
        )
        # Driver bound to VEH001
        user_driver = User(
            id="USR-DRV", username="driver@waypoint.test",
            password_hash=password_hash, role="driver", vehicle_id="VEH001", display_name="Test Driver"
        )
        # Store Manager bound to OUT001
        user_store = User(
            id="USR-STORE", username="store@waypoint.test",
            password_hash=password_hash, role="store_manager", outlet_id="OUT001", display_name="Test Store Manager"
        )
        
        session.add_all([user_dispatcher, user_loader, user_driver, user_store])
        session.commit()
        
        # User Depot Access mappings
        session.add_all([
            UserDepotAccess(user_id="USR-DISP", depot_id="Peliyagoda"),
            UserDepotAccess(user_id="USR-DISP", depot_id="Kandy"),
            UserDepotAccess(user_id="USR-LOAD", depot_id="Peliyagoda"),
        ])
        session.commit()
        
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)
        if os.path.exists("./test_waypoint.db"):
            try:
                os.remove("./test_waypoint.db")
            except Exception:
                pass

@pytest.fixture(scope="function")
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
