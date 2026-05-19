"""Common response schemas used across endpoints."""

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """GET /health response."""
    status: str
    services: dict[str, bool]


class ErrorResponse(BaseModel):
    """Standard error envelope matching docs/api_design.md."""
    error: str
    message: str
    code: int
