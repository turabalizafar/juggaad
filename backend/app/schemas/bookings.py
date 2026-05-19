"""Schemas for booking endpoints — matches docs/api_design.md."""

from pydantic import BaseModel


class BookingCreateRequest(BaseModel):
    """Input body for POST /bookings/create."""
    request_id: str
    provider_id: str
    user_id: str
    time_slot: str


class BookingCreateResponse(BaseModel):
    """Response from POST /bookings/create."""
    booking_id: str
    status: str
    provider_name: str
    eta_minutes: int
    confirmation_text: str
    simulated: bool = True


class BookingStatusResponse(BaseModel):
    """Response from GET /bookings/{booking_id}."""
    booking_id: str
    status: str
    provider_name: str
    eta_minutes: int
    last_updated: str
