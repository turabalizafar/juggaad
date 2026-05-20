"""Schemas for POST /api/v1/book and GET /api/v1/booking/{id}."""

from pydantic import BaseModel

from app.schemas.traces import TraceStep


class BookRequest(BaseModel):
    """Input body for POST /api/v1/book.

    user_id comes from Firebase JWT (get_current_user dependency).
    """
    request_id: str
    provider_id: str
    user_phone_number: str | None = None  # Optional — auto-filled from profile if omitted
    time_slot: str


class BookResponse(BaseModel):
    """Response from POST /api/v1/book."""
    booking_id: str
    tracking_id: str
    status: str
    provider_name: str
    provider_phone: str
    eta_minutes: int
    confirmation_text: str
    simulated: bool = True
    agent_trace: list[TraceStep] = []


class BookingStatusResponse(BaseModel):
    """Response from GET /api/v1/booking/{booking_id}."""
    booking_id: str
    tracking_id: str
    status: str
    provider_name: str
    provider_phone: str
    eta_minutes: int
    last_updated: str
