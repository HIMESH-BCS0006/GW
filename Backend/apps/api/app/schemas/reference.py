from typing import Any, Dict, List, Optional
from pydantic import BaseModel
from datetime import date

class OutletRefResponse(BaseModel):
    outlet_id: str
    brand: str
    district: str
    depot: str
    depot_id: str
    dock_type: str
    parking_constraint: str
    mall_window: Optional[str] = None
    window_open_time: str
    window_close_time: str
    display_name: str

    class Config:
        from_attributes = True

class VehicleRefResponse(BaseModel):
    vehicle_id: str
    type: str
    temp: str
    weight_cap_kg: float
    volume_cap_m3: float
    fuel_type: str
    km_per_l: float
    weekly_fuel_quota_l: float
    depot: str
    depot_id: str

    class Config:
        from_attributes = True

class CalendarDayRefResponse(BaseModel):
    date: date
    dow: int
    dow_name: str
    is_weekend: int
    iso_year: int
    iso_week: int
    is_payday: int
    festival: Optional[str] = None
    festival_ramp: float
    is_holiday: int
    monsoon: int
    is_operating: int

    class Config:
        from_attributes = True

class RefConfigResponse(BaseModel):
    cutoff_time: str = "16:00"
    budget_fresh_min: int = 270
    budget_style_tech_min: int = 480
    unit_constants: Optional[Dict[str, Any]] = None
    business_clock: str
    demo_mode: bool
