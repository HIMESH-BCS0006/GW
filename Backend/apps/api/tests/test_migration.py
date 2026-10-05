import os
import pytest
from alembic.config import Config
from alembic import command
from sqlalchemy import create_engine, inspect

MIGRATION_DB_URL = "sqlite:///./test_migration.db"

def test_alembic_migration_upgrade_downgrade():
    """Tests that Alembic 001_initial_migration applies on an empty DB and downgrades cleanly."""
    if os.path.exists("./test_migration.db"):
        os.remove("./test_migration.db")

    # Path to alembic.ini
    ini_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "alembic.ini"))
    alembic_cfg = Config(ini_path)
    alembic_cfg.set_main_option("sqlalchemy.url", MIGRATION_DB_URL)
    alembic_cfg.set_main_option("script_location", os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "alembic")))

    # 1. Apply upgrade to head
    command.upgrade(alembic_cfg, "head")

    engine = create_engine(MIGRATION_DB_URL)
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    expected_tables = [
        "depots", "districts", "outlets", "vehicles", "users", "user_depot_access",
        "service_allowance", "calendar_days", "road_conditions", "traffic_speed",
        "vehicle_availability", "orders", "outlet_service_state", "plan_runs",
        "trips", "trip_stops", "load_checks", "deferrals", "receipts", "exceptions",
        "fuel_ledger", "events", "notifications", "sync_ops"
    ]

    for table in expected_tables:
        assert table in tables, f"Expected table '{table}' not found after Alembic migration upgrade."

    # 2. Downgrade to base
    command.downgrade(alembic_cfg, "base")

    engine_after = create_engine(MIGRATION_DB_URL)
    inspector_after = inspect(engine_after)
    tables_after = inspector_after.get_table_names()
    assert len(tables_after) == 0 or tables_after == ["alembic_version"], "Tables remain after Alembic migration downgrade."

    # Cleanup
    engine.dispose()
    engine_after.dispose()
    if os.path.exists("./test_migration.db"):
        try:
            os.remove("./test_migration.db")
        except Exception:
            pass
