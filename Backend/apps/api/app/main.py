from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.clock import business_now
from app.core.logging import StructuredLoggingMiddleware
from app.core.errors import (
    AppException,
    app_exception_handler,
    validation_exception_handler,
    generic_http_exception_handler,
)
from app.api import (
    auth_router,
    dispatcher_router,
    loader_router,
    driver_router,
    store_manager_router,
    reference_router,
)

app = FastAPI(
    title="Waypoint Delivery Planning System API",
    description="OpenAPI 3.1 specification for the Waypoint Group delivery planning system.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Register Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(StructuredLoggingMiddleware)

from starlette.exceptions import HTTPException as StarletteHTTPException

# Register Exception Handlers
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(StarletteHTTPException, generic_http_exception_handler)

# Include Routers under /api/v1
api_v1_prefix = "/api/v1"
app.include_router(auth_router, prefix=api_v1_prefix)
app.include_router(dispatcher_router, prefix=api_v1_prefix)
app.include_router(loader_router, prefix=api_v1_prefix)
app.include_router(driver_router, prefix=api_v1_prefix)
app.include_router(store_manager_router, prefix=api_v1_prefix)
app.include_router(reference_router, prefix=api_v1_prefix)

@app.get("/health", tags=["reference"], summary="Health check endpoint")
def health_check():
    """System health check endpoint returning current status and business clock time."""
    now_dt = business_now()
    return {
        "status": "ok",
        "now": now_dt.isoformat(),
        "demo_mode": settings.DEMO_MODE,
    }
