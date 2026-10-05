from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_claims, get_current_user
from app.models.domain import User
from app.schemas.auth import LoginRequest, TokenResponse, UserMeResponse
from app.services.auth_service import login_user, build_user_me_response

router = APIRouter(tags=["auth"])

@router.post("/auth/login", response_model=TokenResponse, summary="Authenticate user and receive JWT bearer token", operation_id="login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """Logs in user with username and password, returning JWT token with role & depot scope claims (D24)."""
    return login_user(db, payload.username, payload.password)

@router.get("/me", response_model=UserMeResponse, summary="Get current logged in user claims and profile", operation_id="getCurrentUser")
def get_me(
    claims: dict = Depends(get_current_user_claims),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    """Returns claims and profile for the authenticated token."""
    response = build_user_me_response(db, claims)
    response.display_name = user.display_name
    return response
