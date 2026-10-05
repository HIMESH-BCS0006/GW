from app.api.auth import router as auth_router
from app.api.dispatcher import router as dispatcher_router
from app.api.loader import router as loader_router
from app.api.driver import router as driver_router
from app.api.store_manager import router as store_manager_router
from app.api.reference import router as reference_router

__all__ = [
    "auth_router",
    "dispatcher_router",
    "loader_router",
    "driver_router",
    "store_manager_router",
    "reference_router",
]
