from datetime import datetime, timezone, timedelta
import zoneinfo
from app.core.config import settings

try:
    COLOMBO_TZ = zoneinfo.ZoneInfo(settings.TIMEZONE)
except Exception:
    COLOMBO_TZ = timezone(timedelta(hours=5, minutes=30), name="Asia/Colombo")

def business_now() -> datetime:
    """
    Returns the current business time (D11).
    When DEMO_MODE is True, returns the fixed DEMO_NOW timestamp.
    Otherwise, returns the current time in Asia/Colombo (UTC+05:30).
    """
    if settings.DEMO_MODE:
        try:
            return datetime.fromisoformat(settings.DEMO_NOW)
        except Exception:
            # Fallback if parsing fails
            return datetime(2025, 7, 31, 14, 0, 0, tzinfo=COLOMBO_TZ)
    return datetime.now(COLOMBO_TZ)

def business_today_date() -> str:
    """Returns YYYY-MM-DD formatted date string of business_now()."""
    return business_now().strftime("%Y-%m-%d")
