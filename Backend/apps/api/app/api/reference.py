import os
import json
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from fastapi.security import HTTPAuthorizationCredentials
from starlette.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.config import settings
from app.core.security import require_roles, decode_access_token, security_scheme
from app.models.domain import Outlet, Vehicle, CalendarDay, Event, Notification
from app.schemas.reference import (
    OutletRefResponse,
    VehicleRefResponse,
    CalendarDayRefResponse,
    RefConfigResponse,
)

router = APIRouter(tags=["reference"])

ALLOWED_ROLES = ["dispatcher", "loader", "driver", "store_manager"]


def load_unit_constants() -> Optional[dict]:
    candidates = [
        "config/unit_constants.json",
        "Backend/config/unit_constants.json",
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "config", "unit_constants.json")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "config", "unit_constants.json")),
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
    return None


@router.get("/ref/outlets", response_model=List[OutletRefResponse], operation_id="getRefOutlets")
def get_ref_outlets(
    claims: dict = Depends(require_roles(ALLOWED_ROLES)),
    db: Session = Depends(get_db),
):
    outlets = db.query(Outlet).all()
    result = []
    for o in outlets:
        result.append(
            OutletRefResponse(
                outlet_id=o.id,
                brand=o.brand,
                district=o.district,
                depot=o.depot_id,
                depot_id=o.depot_id,
                dock_type=o.dock_type,
                parking_constraint=o.parking_constraint,
                mall_window=o.mall_window,
                window_open_time=o.window_open_time,
                window_close_time=o.window_close_time,
                display_name=o.display_name,
            )
        )
    return result


@router.get("/ref/vehicles", response_model=List[VehicleRefResponse], operation_id="getRefVehicles")
def get_ref_vehicles(
    claims: dict = Depends(require_roles(ALLOWED_ROLES)),
    db: Session = Depends(get_db),
):
    vehicles = db.query(Vehicle).all()
    result = []
    for v in vehicles:
        result.append(
            VehicleRefResponse(
                vehicle_id=v.id,
                type=v.type,
                temp=v.temp,
                weight_cap_kg=v.weight_cap_kg,
                volume_cap_m3=v.volume_cap_m3,
                fuel_type=v.fuel_type,
                km_per_l=v.km_per_l,
                weekly_fuel_quota_l=v.weekly_fuel_quota_l,
                depot=v.depot_id,
                depot_id=v.depot_id,
            )
        )
    return result


@router.get("/ref/calendar", response_model=List[CalendarDayRefResponse], operation_id="getRefCalendar")
def get_ref_calendar(
    claims: dict = Depends(require_roles(ALLOWED_ROLES)),
    db: Session = Depends(get_db),
):
    cal_days = db.query(CalendarDay).order_by(CalendarDay.date).all()
    result = []
    for c in cal_days:
        result.append(
            CalendarDayRefResponse(
                date=c.date,
                dow=c.dow,
                dow_name=c.dow_name,
                is_weekend=1 if c.is_weekend else 0,
                iso_year=c.iso_year,
                iso_week=c.iso_week,
                is_payday=1 if c.is_payday else 0,
                festival=c.festival,
                festival_ramp=c.festival_ramp,
                is_holiday=1 if c.is_holiday else 0,
                monsoon=c.monsoon,
                is_operating=1 if c.is_operating else 0,
            )
        )
    return result


@router.get("/ref/config", response_model=RefConfigResponse, operation_id="getRefConfig")
def get_ref_config(
    claims: dict = Depends(require_roles(ALLOWED_ROLES)),
):
    unit_constants = load_unit_constants()
    return RefConfigResponse(
        cutoff_time="16:00",
        budget_fresh_min=270,
        budget_style_tech_min=480,
        unit_constants=unit_constants,
        business_clock=settings.DEMO_NOW,
        demo_mode=settings.DEMO_MODE,
    )


@router.get(
    "/events/stream",
    operation_id="getEventsStream",
)
def get_events_stream_endpoint(
    stream_token: Optional[str] = Query(None),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db),
):
    claims = {}
    token = stream_token or (credentials.credentials if credentials else None)
    if token:
        try:
            claims = decode_access_token(token)
        except Exception:
            pass

    user_role = claims.get("role")
    user_outlet_id = claims.get("outlet_id")
    user_vehicle_id = claims.get("vehicle_id")
    user_depot_ids = claims.get("depot_ids", [])

    def event_generator():
        # Yield connection acknowledged
        yield f"event: connected\ndata: {json.dumps({'status': 'connected', 'role': user_role})}\n\n"

        events = db.query(Event).order_by(Event.created_at.desc()).limit(20).all()
        for ev in reversed(events):
            notif = db.query(Notification).filter_by(event_id=ev.id).first()
            if notif:
                if user_role and notif.audience_role and user_role != "dispatcher" and notif.audience_role != user_role:
                    continue
                if user_role == "store_manager" and user_outlet_id and notif.audience_scope and notif.audience_scope != user_outlet_id:
                    continue
                if user_role == "driver" and user_vehicle_id and notif.audience_scope and notif.audience_scope != user_vehicle_id:
                    continue
                if user_role in ["loader", "dispatcher"] and user_depot_ids and notif.audience_scope and notif.audience_scope not in user_depot_ids:
                    continue

            payload_data = {
                "id": ev.id,
                "type": ev.type,
                "payload": ev.payload,
                "created_at": ev.created_at.isoformat() if ev.created_at else None,
            }
            yield f"event: {ev.type}\ndata: {json.dumps(payload_data)}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")
