"""
Notification and Event service.
"""

from datetime import datetime
import uuid
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from app.core.clock import business_now
from app.models.domain import Event, Notification


def emit_event(
    db: Session,
    event_type: str,
    payload: Dict[str, Any],
    audience_role: Optional[str] = None,
    audience_scope: Optional[str] = None,
    notification_message: Optional[str] = None,
    message: Optional[str] = None,
) -> Event:
    """
    Creates an Event and optionally a Notification.
    """
    now = business_now()
    event_id = f"EVT-{uuid.uuid4().hex[:12].upper()}"
    event = Event(
        id=event_id,
        type=event_type,
        payload=payload,
        created_at=now,
    )
    db.add(event)
    db.flush()

    if audience_role:
        notif_id = f"NOTIF-{uuid.uuid4().hex[:12].upper()}"
        notif = Notification(
            id=notif_id,
            event_id=event_id,
            audience_role=audience_role,
            audience_scope=audience_scope,
            message=message or notification_message or f"Event {event_type}",
            created_at=now,
        )
        db.add(notif)
        db.flush()

    return event


def get_user_notifications(
    db: Session,
    user_role: str,
    user_outlet_id: Optional[str] = None,
    user_depot_ids: Optional[List[str]] = None,
) -> List[Notification]:
    """
    Returns notifications for the user's role and scope.
    """
    query = db.query(Notification).filter(
        (Notification.audience_role == user_role) | (Notification.audience_role == "all")
    )
    all_notifs = query.order_by(Notification.created_at.desc()).all()

    # Filter scope if specified
    filtered = []
    for n in all_notifs:
        if not n.audience_scope:
            filtered.append(n)
        elif user_role == "store_manager" and user_outlet_id and n.audience_scope == user_outlet_id:
            filtered.append(n)
        elif user_role in ("dispatcher", "loader") and user_depot_ids and n.audience_scope in user_depot_ids:
            filtered.append(n)
        elif n.audience_scope == "all":
            filtered.append(n)
        else:
            filtered.append(n)
    return filtered


def mark_notification_as_read(db: Session, notification_id: str) -> Optional[Notification]:
    notif = db.query(Notification).filter_by(id=notification_id).first()
    if notif and not notif.read_at:
        notif.read_at = business_now()
        db.commit()
        db.refresh(notif)
    return notif
