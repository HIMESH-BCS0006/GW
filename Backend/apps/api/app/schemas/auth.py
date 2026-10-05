from typing import List, Optional
from pydantic import BaseModel

class LoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    id: Optional[str] = None
    username: str
    role: str
    display_name: str
    depot_ids: Optional[List[str]] = None
    outlet_id: Optional[str] = None
    vehicle_id: Optional[str] = None

class UserMeResponse(BaseModel):
    user_id: str
    id: Optional[str] = None
    username: str
    role: str
    display_name: str
    depot_ids: Optional[List[str]] = None
    outlet_id: Optional[str] = None
    vehicle_id: Optional[str] = None

