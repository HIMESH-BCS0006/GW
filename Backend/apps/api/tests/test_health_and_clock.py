import pytest
from app.core.clock import business_now
from app.core.config import settings

def test_health_check_endpoint(client):
    """Test /health endpoint returns 200 status ok and business clock timestamp."""
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"
    assert "now" in data
    assert data["demo_mode"] is True

def test_business_now_demo_mode():
    """Test business_now() returns DEMO_NOW when DEMO_MODE is True."""
    settings.DEMO_MODE = True
    settings.DEMO_NOW = "2025-07-31T14:00:00+05:30"
    now_dt = business_now()
    assert now_dt.year == 2025
    assert now_dt.month == 7
    assert now_dt.day == 31
    assert now_dt.hour == 14
