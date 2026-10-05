from datetime import datetime, timedelta, timezone
from typing import List, Optional, Union
import jwt
import bcrypt

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.errors import ForbiddenScopeException, ValidationException
from app.models.domain import User

security_scheme = HTTPBearer(auto_error=False)

def hash_password(password: str) -> str:
    """Hashes plain password using bcrypt."""
    pwd_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')

def verify_password(plain_password: str, password_hash: str) -> bool:
    """Verifies plain password against hashed password."""
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), password_hash.encode('utf-8'))
    except Exception:
        return False

def create_access_token(
    user_id: str,
    username: str,
    role: str,
    depot_ids: Optional[List[str]] = None,
    outlet_id: Optional[str] = None,
    vehicle_id: Optional[str] = None,
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    Creates JWT token with claims per D24:
    user_id, role, depot_ids (dispatcher/loader), outlet_id (store_manager), vehicle_id (driver).
    """
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    payload = {
        "sub": username,
        "user_id": user_id,
        "role": role,
        "depot_ids": depot_ids or [],
        "outlet_id": outlet_id,
        "vehicle_id": vehicle_id,
        "exp": expire,
        "iat": datetime.now(timezone.utc)
    }
    
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def decode_access_token(token: str) -> dict:
    """Decodes and validates JWT token."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

def get_current_user_claims(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme)
) -> dict:
    """Dependency to extract and decode JWT claims."""
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    return decode_access_token(credentials.credentials)

def get_current_user(
    claims: dict = Depends(get_current_user_claims),
    db: Session = Depends(get_db)
) -> User:
    """Dependency to fetch authenticated User model from database."""
    user = db.query(User).filter(User.id == claims["user_id"]).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    return user

def require_roles(allowed_roles: List[str]):
    """Reusable dependency to enforce role-based access control."""
    def role_checker(claims: dict = Depends(get_current_user_claims)):
        user_role = claims.get("role")
        if user_role not in allowed_roles:
            raise ForbiddenScopeException(
                message=f"Role '{user_role}' is not allowed to access this resource. Allowed roles: {allowed_roles}"
            )
        return claims
    return role_checker

def check_depot_scope(depot_id: Optional[str], claims: dict) -> str:
    """
    Enforces D24 depot scope rules:
    - Defaults to first depot if user has access and none is provided.
    - 403 FORBIDDEN_SCOPE if depot is outside user's access list.
    """
    user_depots = claims.get("depot_ids") or []
    
    if not depot_id:
        if len(user_depots) >= 1:
            return user_depots[0]
        else:
            raise ForbiddenScopeException(message="User has no assigned depot access")
            
    if user_depots and depot_id not in user_depots:
        raise ForbiddenScopeException(
            message=f"Access to depot '{depot_id}' is forbidden for user with access: {user_depots}"
        )
        
    return depot_id
