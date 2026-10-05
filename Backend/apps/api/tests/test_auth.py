import pytest
from app.core.security import check_depot_scope, decode_access_token
from app.core.errors import ForbiddenScopeException, ValidationException

def test_login_dispatcher_claims(client):
    """Test login as dispatcher returns D24 claims (user_id, role, depot_ids)."""
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "dispatcher@waypoint.test", "password": "pass123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["role"] == "dispatcher"
    assert data["user_id"] == "USR-DISP"
    assert set(data["depot_ids"]) == {"Peliyagoda", "Kandy"}

    # Decode JWT and verify claims inside token
    claims = decode_access_token(data["access_token"])
    assert claims["user_id"] == "USR-DISP"
    assert claims["role"] == "dispatcher"
    assert set(claims["depot_ids"]) == {"Peliyagoda", "Kandy"}

def test_login_driver_claims(client):
    """Test login as driver returns vehicle_id claim."""
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "driver@waypoint.test", "password": "pass123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "driver"
    assert data["vehicle_id"] == "VEH001"

def test_login_store_manager_claims(client):
    """Test login as store manager returns outlet_id claim."""
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "store@waypoint.test", "password": "pass123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "store_manager"
    assert data["outlet_id"] == "OUT001"

def test_get_me_with_valid_token(client):
    """Test GET /me returns correct profile with valid Bearer token."""
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "dispatcher@waypoint.test", "password": "pass123"}
    )
    token = login_res.json()["access_token"]

    me_res = client.get(
        "/api/v1/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert me_res.status_code == 200
    me_data = me_res.json()
    assert me_data["user_id"] == "USR-DISP"
    assert me_data["username"] == "dispatcher@waypoint.test"

def test_401_without_token(client):
    """Test 401 response when accessing protected endpoints without token."""
    res = client.get("/api/v1/me")
    assert res.status_code == 401
    assert "error" in res.json()
    assert res.json()["error"]["code"] == "UNAUTHORIZED"

def test_401_invalid_credentials(client):
    """Test 401 response on invalid login credentials."""
    res = client.post(
        "/api/v1/auth/login",
        json={"username": "dispatcher@waypoint.test", "password": "wrong_password"}
    )
    assert res.status_code == 401

def test_403_wrong_depot_scope_d24():
    """Test D24 depot scope checking logic."""
    # User with access to 1 depot: defaults if missing
    single_depot_claims = {"depot_ids": ["Peliyagoda"]}
    assert check_depot_scope(None, single_depot_claims) == "Peliyagoda"
    assert check_depot_scope("Peliyagoda", single_depot_claims) == "Peliyagoda"

    # User with access to 1 depot: 403 if accessing outside depot
    with pytest.raises(ForbiddenScopeException):
        check_depot_scope("Kandy", single_depot_claims)

    # User with multiple depots: 422 if depot_id query parameter missing
    multi_depot_claims = {"depot_ids": ["Peliyagoda", "Kandy"]}
    with pytest.raises(ValidationException):
        check_depot_scope(None, multi_depot_claims)

    # User with multiple depots: allowed if depot_id is in list
    assert check_depot_scope("Kandy", multi_depot_claims) == "Kandy"

    # User with multiple depots: 403 if depot_id is outside list
    with pytest.raises(ForbiddenScopeException):
        check_depot_scope("Galle", multi_depot_claims)
