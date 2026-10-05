"""initial_migration

Revision ID: 001_initial_migration
Revises: 
Create Date: 2026-10-03 15:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "001_initial_migration"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # 1. depots
    op.create_table(
        "depots",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 2. districts
    op.create_table(
        "districts",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("depot_id", sa.String(), sa.ForeignKey("depots.id"), nullable=False),
        sa.Column("road_class", sa.String(), nullable=False),
        sa.Column("free_flow_kmh", sa.Integer(), nullable=False),
        sa.Column("depot_to_district_km", sa.Float(), nullable=False),
        sa.Column("depot_to_district_freeflow_min", sa.Integer(), nullable=False),
        sa.Column("inter_stop_km", sa.Float(), nullable=False),
        sa.Column("inter_stop_freeflow_min", sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 3. outlets
    op.create_table(
        "outlets",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("brand", sa.String(), nullable=False),
        sa.Column("district", sa.String(), nullable=False),
        sa.Column("depot_id", sa.String(), sa.ForeignKey("depots.id"), nullable=False),
        sa.Column("dock_type", sa.String(), nullable=False),
        sa.Column("parking_constraint", sa.String(), nullable=False),
        sa.Column("mall_window", sa.String(), nullable=True),
        sa.Column("window_open_time", sa.String(), nullable=False),
        sa.Column("window_close_time", sa.String(), nullable=False),
        sa.Column("display_name", sa.String(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 4. vehicles
    op.create_table(
        "vehicles",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("type", sa.String(), nullable=False),
        sa.Column("temp", sa.String(), nullable=False),
        sa.Column("weight_cap_kg", sa.Float(), nullable=False),
        sa.Column("volume_cap_m3", sa.Float(), nullable=False),
        sa.Column("fuel_type", sa.String(), nullable=False),
        sa.Column("km_per_l", sa.Float(), nullable=False),
        sa.Column("weekly_fuel_quota_l", sa.Float(), nullable=False),
        sa.Column("depot_id", sa.String(), sa.ForeignKey("depots.id"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 5. users
    op.create_table(
        "users",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("username", sa.String(), nullable=False),
        sa.Column("password_hash", sa.String(), nullable=False),
        sa.Column("role", sa.String(), nullable=False),
        sa.Column("outlet_id", sa.String(), sa.ForeignKey("outlets.id"), nullable=True),
        sa.Column("vehicle_id", sa.String(), sa.ForeignKey("vehicles.id"), nullable=True),
        sa.Column("display_name", sa.String(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_users_id"), "users", ["id"], unique=False)
    op.create_index(op.f("ix_users_username"), "users", ["username"], unique=True)

    # 6. user_depot_access
    op.create_table(
        "user_depot_access",
        sa.Column("user_id", sa.String(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("depot_id", sa.String(), sa.ForeignKey("depots.id", ondelete="CASCADE"), nullable=False),
        sa.PrimaryKeyConstraint("user_id", "depot_id"),
    )

    # 7. service_allowance
    op.create_table(
        "service_allowance",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("brand", sa.String(), nullable=False),
        sa.Column("dock_type", sa.String(), nullable=False),
        sa.Column("service_allowance_min", sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 8. calendar_days
    op.create_table(
        "calendar_days",
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("dow", sa.Integer(), nullable=False),
        sa.Column("dow_name", sa.String(), nullable=False),
        sa.Column("is_weekend", sa.Boolean(), nullable=False),
        sa.Column("iso_year", sa.Integer(), nullable=False),
        sa.Column("iso_week", sa.Integer(), nullable=False),
        sa.Column("is_payday", sa.Boolean(), nullable=False),
        sa.Column("festival", sa.String(), nullable=True),
        sa.Column("festival_ramp", sa.Float(), nullable=False),
        sa.Column("is_holiday", sa.Boolean(), nullable=False),
        sa.Column("monsoon", sa.Integer(), nullable=False),
        sa.Column("is_operating", sa.Boolean(), nullable=False),
        sa.PrimaryKeyConstraint("date"),
    )

    # 9. road_conditions
    op.create_table(
        "road_conditions",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("district", sa.String(), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("disruption_index", sa.Float(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 10. traffic_speed
    op.create_table(
        "traffic_speed",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("district", sa.String(), nullable=False),
        sa.Column("hour", sa.Integer(), nullable=False),
        sa.Column("monsoon", sa.Boolean(), nullable=False),
        sa.Column("speed_index", sa.Float(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 11. vehicle_availability
    op.create_table(
        "vehicle_availability",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("vehicle_id", sa.String(), sa.ForeignKey("vehicles.id"), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("note", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("vehicle_id", "date", name="uq_vehicle_availability_date"),
    )

    # 12. orders
    op.create_table(
        "orders",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("outlet_id", sa.String(), sa.ForeignKey("outlets.id"), nullable=False),
        sa.Column("delivery_date", sa.Date(), nullable=False),
        sa.Column("requested_delivery_date", sa.Date(), nullable=True),
        sa.Column("placed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("temp_requirement", sa.String(), nullable=False),
        sa.Column("order_units", sa.Integer(), nullable=False),
        sa.Column("order_weight_kg", sa.Float(), nullable=False),
        sa.Column("order_volume_m3", sa.Float(), nullable=False),
        sa.Column("rolled_over", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("deferral_count", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("cancel_reason", sa.String(), nullable=True),
        sa.Column("note", sa.String(), nullable=True),
        sa.Column("client_op_id", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # 13. outlet_service_state
    op.create_table(
        "outlet_service_state",
        sa.Column("outlet_id", sa.String(), sa.ForeignKey("outlets.id"), nullable=False),
        sa.Column("last_served_date", sa.Date(), nullable=True),
        sa.Column("last_deferred_date", sa.Date(), nullable=True),
        sa.Column("consecutive_deferrals", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.PrimaryKeyConstraint("outlet_id"),
    )

    # 14. plan_runs
    op.create_table(
        "plan_runs",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("depot_id", sa.String(), sa.ForeignKey("depots.id"), nullable=False),
        sa.Column("delivery_date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False, server_default=sa.text("1")),
        sa.Column("generated_by", sa.String(), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ranking_config_json", sa.JSON(), nullable=True),
        sa.Column("summary_json", sa.JSON(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # 15. trips
    op.create_table(
        "trips",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("plan_run_id", sa.String(), sa.ForeignKey("plan_runs.id"), nullable=False),
        sa.Column("vehicle_id", sa.String(), sa.ForeignKey("vehicles.id"), nullable=False),
        sa.Column("depot_id", sa.String(), sa.ForeignKey("depots.id"), nullable=False),
        sa.Column("delivery_date", sa.Date(), nullable=False),
        sa.Column("trip_no", sa.Integer(), nullable=False),
        sa.Column("brand", sa.String(), nullable=False),
        sa.Column("district", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("plan_version", sa.Integer(), nullable=False, server_default=sa.text("1")),
        sa.Column("depart_time", sa.String(), nullable=True),
        sa.Column("est_minutes", sa.Integer(), nullable=True),
        sa.Column("est_km", sa.Float(), nullable=True),
        sa.Column("est_fuel_l", sa.Float(), nullable=True),
        sa.Column("confirmed_by", sa.String(), nullable=True),
        sa.Column("confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("trip_no IN (1, 2)", name="chk_trip_no_valid"),
        sa.UniqueConstraint("vehicle_id", "delivery_date", "trip_no", name="uq_vehicle_delivery_trip_no"),
        sa.PrimaryKeyConstraint("id"),
    )

    # 16. trip_stops
    op.create_table(
        "trip_stops",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), sa.ForeignKey("trips.id"), nullable=False),
        sa.Column("order_id", sa.String(), sa.ForeignKey("orders.id"), nullable=False),
        sa.Column("seq", sa.Integer(), nullable=False),
        sa.Column("eta", sa.String(), nullable=True),
        sa.Column("service_start_est", sa.String(), nullable=True),
        sa.Column("service_min", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("receipt_status", sa.String(), nullable=False, server_default="NONE"),
        sa.Column("arrived_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("outcome", sa.String(), nullable=True),
        sa.Column("quantity_delivered", sa.Integer(), nullable=True),
        sa.Column("received_by", sa.String(), nullable=True),
        sa.Column("outcome_note", sa.String(), nullable=True),
        sa.Column("device_ts", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("order_id"),
        sa.PrimaryKeyConstraint("id"),
    )

    # 17. load_checks
    op.create_table(
        "load_checks",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), sa.ForeignKey("trips.id"), nullable=False),
        sa.Column("order_id", sa.String(), sa.ForeignKey("orders.id"), nullable=False),
        sa.Column("plan_version", sa.Integer(), nullable=False),
        sa.Column("expected_qty", sa.Integer(), nullable=False),
        sa.Column("loaded_qty", sa.Integer(), nullable=False),
        sa.Column("issue", sa.String(), nullable=False),
        sa.Column("note", sa.String(), nullable=True),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("resolution", sa.String(), nullable=True),
        sa.Column("reported_by", sa.String(), nullable=False),
        sa.Column("resolved_by", sa.String(), nullable=True),
        sa.Column("vehicle_id", sa.String(), nullable=True),
        sa.Column("outlet_id", sa.String(), nullable=True),
        sa.Column("outlet_name", sa.String(), nullable=True),
        sa.Column("bay", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # 18. deferrals
    op.create_table(
        "deferrals",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("order_id", sa.String(), sa.ForeignKey("orders.id"), nullable=False),
        sa.Column("from_delivery_date", sa.Date(), nullable=False),
        sa.Column("reason_code", sa.String(), nullable=False),
        sa.Column("reason_class", sa.String(), nullable=False),
        sa.Column("reason_text", sa.String(), nullable=False),
        sa.Column("consequence_text", sa.String(), nullable=True),
        sa.Column("details_json", sa.JSON(), nullable=True),
        sa.Column("decided_by", sa.String(), nullable=False),
        sa.Column("decided_by_user", sa.String(), nullable=True),
        sa.Column("decided_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("resolved_to_date", sa.Date(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # 19. receipts
    op.create_table(
        "receipts",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("stop_id", sa.String(), sa.ForeignKey("trip_stops.id"), nullable=False),
        sa.Column("outcome", sa.String(), nullable=False),
        sa.Column("note", sa.String(), nullable=True),
        sa.Column("confirmed_by", sa.String(), nullable=False),
        sa.Column("confirmed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("qr_token", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # 20. exceptions
    op.create_table(
        "exceptions",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("trip_id", sa.String(), sa.ForeignKey("trips.id"), nullable=False),
        sa.Column("stop_id", sa.String(), sa.ForeignKey("trip_stops.id"), nullable=True),
        sa.Column("type", sa.String(), nullable=False),
        sa.Column("note", sa.String(), nullable=True),
        sa.Column("reported_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("decision", sa.String(), nullable=True),
        sa.Column("decision_note", sa.String(), nullable=True),
        sa.Column("decided_by", sa.String(), nullable=True),
        sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # 21. fuel_ledger
    op.create_table(
        "fuel_ledger",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("vehicle_id", sa.String(), sa.ForeignKey("vehicles.id"), nullable=False),
        sa.Column("iso_year", sa.Integer(), nullable=False),
        sa.Column("iso_week", sa.Integer(), nullable=False),
        sa.Column("litres_committed", sa.Float(), nullable=False),
        sa.UniqueConstraint("vehicle_id", "iso_year", "iso_week", name="uq_vehicle_iso_week"),
        sa.PrimaryKeyConstraint("id"),
    )

    # 22. events
    op.create_table(
        "events",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("type", sa.String(), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 23. notifications
    op.create_table(
        "notifications",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("event_id", sa.String(), sa.ForeignKey("events.id"), nullable=True),
        sa.Column("audience_role", sa.String(), nullable=False),
        sa.Column("audience_scope", sa.String(), nullable=True),
        sa.Column("message", sa.String(), nullable=True),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    # 24. sync_ops
    op.create_table(
        "sync_ops",
        sa.Column("client_op_id", sa.String(), nullable=False),
        sa.Column("device_id", sa.String(), nullable=False),
        sa.Column("client_seq", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.String(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("op_type", sa.String(), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("client_ts", sa.DateTime(timezone=True), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("applied_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("result", sa.String(), nullable=False),
        sa.Column("reason", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("client_op_id"),
    )


def downgrade() -> None:
    op.drop_table("sync_ops")
    op.drop_table("notifications")
    op.drop_table("events")
    op.drop_table("fuel_ledger")
    op.drop_table("exceptions")
    op.drop_table("receipts")
    op.drop_table("deferrals")
    op.drop_table("load_checks")
    op.drop_table("trip_stops")
    op.drop_table("trips")
    op.drop_table("plan_runs")
    op.drop_table("outlet_service_state")
    op.drop_table("orders")
    op.drop_table("vehicle_availability")
    op.drop_table("traffic_speed")
    op.drop_table("road_conditions")
    op.drop_table("calendar_days")
    op.drop_table("service_allowance")
    op.drop_table("user_depot_access")
    op.drop_index(op.f("ix_users_username"), table_name="users")
    op.drop_index(op.f("ix_users_id"), table_name="users")
    op.drop_table("users")
    op.drop_table("vehicles")
    op.drop_table("outlets")
    op.drop_table("districts")
    op.drop_table("depots")
