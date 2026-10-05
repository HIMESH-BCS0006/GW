from sqlalchemy import (
    Column, String, Integer, Float, Boolean, Date, DateTime, JSON, ForeignKey, UniqueConstraint, CheckConstraint
)
from sqlalchemy.orm import relationship
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, nullable=False)  # dispatcher, loader, driver, store_manager
    outlet_id = Column(String, ForeignKey("outlets.id"), nullable=True)
    vehicle_id = Column(String, ForeignKey("vehicles.id"), nullable=True)
    display_name = Column(String, nullable=False)

    depot_access = relationship("UserDepotAccess", back_populates="user", cascade="all, delete-orphan")


class UserDepotAccess(Base):
    __tablename__ = "user_depot_access"

    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    depot_id = Column(String, ForeignKey("depots.id", ondelete="CASCADE"), primary_key=True)

    user = relationship("User", back_populates="depot_access")


class Depot(Base):
    __tablename__ = "depots"

    id = Column(String, primary_key=True)  # e.g. Peliyagoda, Kandy
    name = Column(String, nullable=False)


class District(Base):
    __tablename__ = "districts"

    id = Column(String, primary_key=True)
    depot_id = Column(String, ForeignKey("depots.id"), nullable=False)
    road_class = Column(String, nullable=False)
    free_flow_kmh = Column(Integer, nullable=False)
    depot_to_district_km = Column(Float, nullable=False)
    depot_to_district_freeflow_min = Column(Integer, nullable=False)
    inter_stop_km = Column(Float, nullable=False)
    inter_stop_freeflow_min = Column(Integer, nullable=False)


class Outlet(Base):
    __tablename__ = "outlets"

    id = Column(String, primary_key=True)
    brand = Column(String, nullable=False)  # Fresh, Style, Tech
    district = Column(String, nullable=False)
    depot_id = Column(String, ForeignKey("depots.id"), nullable=False)
    dock_type = Column(String, nullable=False)  # rear_dock, street, mall_bay
    parking_constraint = Column(String, nullable=False)  # normal, van_only, mall_dock
    mall_window = Column(String, nullable=True)
    window_open_time = Column(String, nullable=False)
    window_close_time = Column(String, nullable=False)
    display_name = Column(String, nullable=False)  # D23, e.g. "Fresh Colombo 03"


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(String, primary_key=True)
    type = Column(String, nullable=False)  # truck, van
    temp = Column(String, nullable=False)  # chilled, ambient
    weight_cap_kg = Column(Float, nullable=False)
    volume_cap_m3 = Column(Float, nullable=False)
    fuel_type = Column(String, nullable=False)
    km_per_l = Column(Float, nullable=False)
    weekly_fuel_quota_l = Column(Float, nullable=False)
    depot_id = Column(String, ForeignKey("depots.id"), nullable=False)


class ServiceAllowance(Base):
    __tablename__ = "service_allowance"

    id = Column(Integer, primary_key=True, autoincrement=True)
    brand = Column(String, nullable=False)
    dock_type = Column(String, nullable=False)
    service_allowance_min = Column(Integer, nullable=False)


class CalendarDay(Base):
    __tablename__ = "calendar_days"

    date = Column(Date, primary_key=True)
    dow = Column(Integer, nullable=False)
    dow_name = Column(String, nullable=False)
    is_weekend = Column(Boolean, nullable=False)
    iso_year = Column(Integer, nullable=False)
    iso_week = Column(Integer, nullable=False)
    is_payday = Column(Boolean, nullable=False)
    festival = Column(String, nullable=True)
    festival_ramp = Column(Float, nullable=False)
    is_holiday = Column(Boolean, nullable=False)
    monsoon = Column(Integer, nullable=False)
    is_operating = Column(Boolean, nullable=False)


class RoadCondition(Base):
    __tablename__ = "road_conditions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    district = Column(String, nullable=False)
    date = Column(Date, nullable=False)
    disruption_index = Column(Float, nullable=False)


class TrafficSpeed(Base):
    __tablename__ = "traffic_speed"

    id = Column(Integer, primary_key=True, autoincrement=True)
    district = Column(String, nullable=False)
    hour = Column(Integer, nullable=False)
    monsoon = Column(Boolean, nullable=False)
    speed_index = Column(Float, nullable=False)


class VehicleAvailability(Base):
    __tablename__ = "vehicle_availability"

    id = Column(Integer, primary_key=True, autoincrement=True)
    vehicle_id = Column(String, ForeignKey("vehicles.id"), nullable=False)
    date = Column(Date, nullable=False)
    status = Column(String, nullable=False)  # available, in_workshop
    note = Column(String, nullable=True)

    __table_args__ = (
        UniqueConstraint("vehicle_id", "date", name="uq_vehicle_availability_date"),
    )


class Order(Base):
    __tablename__ = "orders"

    id = Column(String, primary_key=True)
    outlet_id = Column(String, ForeignKey("outlets.id"), nullable=False)
    delivery_date = Column(Date, nullable=False)
    requested_delivery_date = Column(Date, nullable=True)
    placed_at = Column(DateTime(timezone=True), nullable=False)
    status = Column(String, nullable=False)  # SUBMITTED, PLANNED, SCHEDULED, LOADED, IN_TRANSIT, DELIVERED, PARTIALLY_DELIVERED, DEFERRED, CANCELLED
    temp_requirement = Column(String, nullable=False)  # chilled, ambient
    order_units = Column(Integer, nullable=False)
    order_weight_kg = Column(Float, nullable=False)  # D18: NOT NULL
    order_volume_m3 = Column(Float, nullable=False)  # D18: NOT NULL
    rolled_over = Column(Boolean, default=False, nullable=False)
    deferral_count = Column(Integer, default=0, nullable=False)
    cancel_reason = Column(String, nullable=True)
    note = Column(String, nullable=True)
    client_op_id = Column(String, nullable=True)


class OutletServiceState(Base):
    __tablename__ = "outlet_service_state"

    outlet_id = Column(String, ForeignKey("outlets.id"), primary_key=True)
    last_served_date = Column(Date, nullable=True)
    last_deferred_date = Column(Date, nullable=True)
    consecutive_deferrals = Column(Integer, default=0, nullable=False)


class PlanRun(Base):
    __tablename__ = "plan_runs"

    id = Column(String, primary_key=True)
    depot_id = Column(String, ForeignKey("depots.id"), nullable=False)
    delivery_date = Column(Date, nullable=False)
    status = Column(String, nullable=False)  # OPEN, CLOSED
    version = Column(Integer, default=1, nullable=False)
    generated_by = Column(String, nullable=False)
    generated_at = Column(DateTime(timezone=True), nullable=False)
    ranking_config_json = Column(JSON, nullable=True)
    summary_json = Column(JSON, nullable=True)


class Trip(Base):
    __tablename__ = "trips"

    id = Column(String, primary_key=True)
    plan_run_id = Column(String, ForeignKey("plan_runs.id"), nullable=False)
    vehicle_id = Column(String, ForeignKey("vehicles.id"), nullable=False)
    depot_id = Column(String, ForeignKey("depots.id"), nullable=False)
    delivery_date = Column(Date, nullable=False)
    trip_no = Column(Integer, nullable=False)  # 1 or 2
    brand = Column(String, nullable=False)  # D19 update
    district = Column(String, nullable=False)  # D19 update
    status = Column(String, nullable=False)  # DRAFT, CONFIRMED, LOADING, BLOCKED, LOADED, IN_PROGRESS, COMPLETED, CANCELLED
    plan_version = Column(Integer, default=1, nullable=False)  # D19 update
    depart_time = Column(String, nullable=True)
    est_minutes = Column(Integer, nullable=True)
    est_km = Column(Float, nullable=True)
    est_fuel_l = Column(Float, nullable=True)
    confirmed_by = Column(String, nullable=True)
    confirmed_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        CheckConstraint("trip_no IN (1, 2)", name="chk_trip_no_valid"),
        UniqueConstraint("vehicle_id", "delivery_date", "trip_no", name="uq_vehicle_delivery_trip_no"),
    )


class TripStop(Base):
    __tablename__ = "trip_stops"

    id = Column(String, primary_key=True)
    trip_id = Column(String, ForeignKey("trips.id"), nullable=False)
    order_id = Column(String, ForeignKey("orders.id"), unique=True, nullable=False)
    seq = Column(Integer, nullable=False)
    eta = Column(String, nullable=True)
    service_start_est = Column(String, nullable=True)
    service_min = Column(Integer, nullable=False)
    status = Column(String, nullable=False)  # PENDING, ARRIVED, DELIVERED, PARTIAL, FAILED, SKIPPED, EXCEPTION
    receipt_status = Column(String, nullable=False, default="NONE")  # NONE, AWAITING, CONFIRMED, DISCREPANCY
    arrived_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    outcome = Column(String, nullable=True)  # delivered, partial, refused, closed
    quantity_delivered = Column(Integer, nullable=True)
    received_by = Column(String, nullable=True)
    outcome_note = Column(String, nullable=True)
    device_ts = Column(DateTime(timezone=True), nullable=True)


class LoadCheck(Base):
    __tablename__ = "load_checks"

    id = Column(String, primary_key=True)
    trip_id = Column(String, ForeignKey("trips.id"), nullable=False)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False)
    plan_version = Column(Integer, nullable=False)
    expected_qty = Column(Integer, nullable=False)
    loaded_qty = Column(Integer, nullable=False)
    issue = Column(String, nullable=False)  # missing, damaged
    note = Column(String, nullable=True)
    status = Column(String, nullable=False)  # OPEN, RESOLVED
    resolution = Column(String, nullable=True)  # defer_order, replan_order, proceed_partial
    reported_by = Column(String, nullable=False)
    resolved_by = Column(String, nullable=True)
    vehicle_id = Column(String, nullable=True)
    outlet_id = Column(String, nullable=True)
    outlet_name = Column(String, nullable=True)
    bay = Column(String, nullable=True)


class Deferral(Base):
    __tablename__ = "deferrals"

    id = Column(String, primary_key=True)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False)
    from_delivery_date = Column(Date, nullable=False)
    reason_code = Column(String, nullable=False)
    reason_class = Column(String, nullable=False)  # UNAVOIDABLE, CHOICE, OPERATIONAL, DISPATCHER
    reason_text = Column(String, nullable=False)
    consequence_text = Column(String, nullable=True)
    details_json = Column(JSON, nullable=True)
    decided_by = Column(String, nullable=False)  # engine, dispatcher, system
    decided_by_user = Column(String, nullable=True)
    decided_at = Column(DateTime(timezone=True), nullable=False)
    notified_at = Column(DateTime(timezone=True), nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    resolved_to_date = Column(Date, nullable=True)


class Receipt(Base):
    __tablename__ = "receipts"

    id = Column(String, primary_key=True)
    stop_id = Column(String, ForeignKey("trip_stops.id"), nullable=False)
    outcome = Column(String, nullable=False)  # full, discrepancy
    note = Column(String, nullable=True)
    confirmed_by = Column(String, nullable=False)
    confirmed_at = Column(DateTime(timezone=True), nullable=False)
    qr_token = Column(String, nullable=True)


class ExceptionRecord(Base):
    __tablename__ = "exceptions"

    id = Column(String, primary_key=True)
    trip_id = Column(String, ForeignKey("trips.id"), nullable=False)
    stop_id = Column(String, ForeignKey("trip_stops.id"), nullable=True)
    type = Column(String, nullable=False)  # dock_blocked, outlet_closed, vehicle_issue, access_problem, other
    note = Column(String, nullable=True)
    reported_at = Column(DateTime(timezone=True), nullable=False)
    status = Column(String, nullable=False)  # OPEN, DECIDED
    decision = Column(String, nullable=True)  # retry, skip
    decision_note = Column(String, nullable=True)
    decided_by = Column(String, nullable=True)
    decided_at = Column(DateTime(timezone=True), nullable=True)


class FuelLedger(Base):
    __tablename__ = "fuel_ledger"

    id = Column(Integer, primary_key=True, autoincrement=True)
    vehicle_id = Column(String, ForeignKey("vehicles.id"), nullable=False)
    iso_year = Column(Integer, nullable=False)
    iso_week = Column(Integer, nullable=False)
    litres_committed = Column(Float, nullable=False)

    __table_args__ = (
        UniqueConstraint("vehicle_id", "iso_year", "iso_week", name="uq_vehicle_iso_week"),
    )


class Event(Base):
    __tablename__ = "events"

    id = Column(String, primary_key=True)
    type = Column(String, nullable=False)
    payload = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False)


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True)
    event_id = Column(String, ForeignKey("events.id"), nullable=True)
    audience_role = Column(String, nullable=False)
    audience_scope = Column(String, nullable=True)
    message = Column(String, nullable=True)
    read_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False)


class SyncOp(Base):
    __tablename__ = "sync_ops"

    client_op_id = Column(String, primary_key=True)
    device_id = Column(String, nullable=False)
    client_seq = Column(Integer, nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    op_type = Column(String, nullable=False)
    payload = Column(JSON, nullable=False)
    client_ts = Column(DateTime(timezone=True), nullable=False)
    received_at = Column(DateTime(timezone=True), nullable=False)
    applied_at = Column(DateTime(timezone=True), nullable=True)
    result = Column(String, nullable=False)  # applied, replayed, applied_with_conflict, rejected
    reason = Column(String, nullable=True)
