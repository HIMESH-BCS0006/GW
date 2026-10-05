"""
Notification and Event schemas matching openapi.yaml.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    event_id: Optional[str] = None
    audience_role: str
    audience_scope: Optional[str] = None
    read_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    message: Optional[str] = None
