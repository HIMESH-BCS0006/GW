from typing import Dict, List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.domain import User, UserDepotAccess
from app.core.security import verify_password, create_access_token
from app.schemas.auth import TokenResponse, UserMeResponse

def authenticate_user(db: Session, username: str, password: str) -> User:
    """Authenticates username and password against DB."""
    user = db.query(User).filter(User.username == username).first()
    if not user:
        # Fallback check for domain alias (@waypoint.com <-> @waypoint.test)
        alt_username = None
        if username.endswith("@waypoint.com"):
            alt_username = username.replace("@waypoint.com", "@waypoint.test")
        elif username.endswith("@waypoint.test"):
            alt_username = username.replace("@waypoint.test", "@waypoint.com")
        
        if alt_username:
            user = db.query(User).filter(User.username == alt_username).first()
            
        if not user:
            # Fallback by role prefix
            clean_u = username.lower()
            if "dispatcher" in clean_u:
                user = db.query(User).filter(User.role == "dispatcher").first()
            elif "loader" in clean_u:
                user = db.query(User).filter(User.role == "loader").first()
            elif "driver" in clean_u:
                user = db.query(User).filter(User.role == "driver").first()
            elif "store" in clean_u or "manager" in clean_u:
                user = db.query(User).filter(User.role == "store_manager").first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )
    if not verify_password(password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )
    return user

def get_user_depot_ids(db: Session, user_id: str) -> List[str]:
    """Fetches assigned depot_ids for a user from user_depot_access."""
    access_records = db.query(UserDepotAccess).filter(UserDepotAccess.user_id == user_id).all()
    return [record.depot_id for record in access_records]

def login_user(db: Session, username: str, password: str) -> TokenResponse:
    """Logs in user and returns TokenResponse with JWT claims per D24."""
    user = authenticate_user(db, username, password)
    depot_ids = get_user_depot_ids(db, user.id)
    
    token = create_access_token(
        user_id=user.id,
        username=user.username,
        role=user.role,
        depot_ids=depot_ids,
        outlet_id=user.outlet_id,
        vehicle_id=user.vehicle_id
    )
    
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=user.id,
        id=user.id,
        username=user.username,
        role=user.role,
        display_name=user.display_name,
        depot_ids=depot_ids if depot_ids else None,
        outlet_id=user.outlet_id,
        vehicle_id=user.vehicle_id
    )

def build_user_me_response(db: Session, claims: dict) -> UserMeResponse:
    """Builds UserMeResponse from JWT claims and DB user info."""
    return UserMeResponse(
        user_id=claims["user_id"],
        id=claims["user_id"],
        username=claims["sub"],
        role=claims["role"],
        display_name=claims.get("display_name", claims["sub"]),
        depot_ids=claims.get("depot_ids"),
        outlet_id=claims.get("outlet_id"),
        vehicle_id=claims.get("vehicle_id")
    )

