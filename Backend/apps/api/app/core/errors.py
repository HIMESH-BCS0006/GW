from typing import Any, Dict, Optional
from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

class AppException(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        details: Optional[Dict[str, Any]] = None
    ):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(message)

class ValidationException(AppException):
    def __init__(self, message: str = "Validation error", details: Optional[Dict[str, Any]] = None):
        super().__init__(
            code="VALIDATION_ERROR",
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details=details
        )

class ForbiddenScopeException(AppException):
    def __init__(self, message: str = "Access to requested depot or resource scope forbidden"):
        super().__init__(
            code="FORBIDDEN_SCOPE",
            message=message,
            status_code=status.HTTP_403_FORBIDDEN
        )

class InvalidTransitionException(AppException):
    def __init__(self, message: str = "Invalid state transition for entity"):
        super().__init__(
            code="INVALID_TRANSITION",
            message=message,
            status_code=status.HTTP_409_CONFLICT
        )

class ConstraintViolationException(AppException):
    def __init__(self, message: str = "Plan breaks hard constraint H1-H12", violations: Optional[list] = None):
        super().__init__(
            code="CONSTRAINT_VIOLATION",
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"violations": violations or []}
        )

class StalePlanVersionException(AppException):
    def __init__(self, message: str = "Plan version is stale"):
        super().__init__(
            code="STALE_PLAN_VERSION",
            message=message,
            status_code=status.HTTP_409_CONFLICT
        )

class OpenShortfallException(AppException):
    def __init__(self, message: str = "Trip has open loading shortfalls"):
        super().__init__(
            code="OPEN_SHORTFALL",
            message=message,
            status_code=status.HTTP_409_CONFLICT
        )

class NotOperatingDayException(AppException):
    def __init__(self, message: str = "Requested date is not an operating day"):
        super().__init__(
            code="NOT_OPERATING_DAY",
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY
        )

def format_error_response(code: str, message: str, details: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    return {
        "error": {
            "code": code,
            "message": message,
            "details": details or {}
        }
    }

async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=format_error_response(exc.code, exc.message, exc.details)
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=format_error_response(
            code="VALIDATION_ERROR",
            message="Request input validation failed",
            details={"errors": exc.errors()}
        )
    )

async def generic_http_exception_handler(request: Request, exc: Any) -> JSONResponse:
    status_code = getattr(exc, "status_code", status.HTTP_500_INTERNAL_SERVER_ERROR)
    code = "UNAUTHORIZED" if status_code == status.HTTP_401_UNAUTHORIZED else "ERROR"
    message = getattr(exc, "detail", str(exc))
    return JSONResponse(
        status_code=status_code,
        content=format_error_response(code=code, message=message)
    )
