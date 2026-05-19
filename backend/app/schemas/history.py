"""Schemas for history endpoints (past requests and bookings)."""

from pydantic import BaseModel


class HistoryRequestItem(BaseModel):
    """Single past service request for history listing."""
    request_id: str
    service_type: str
    location_text: str | None = None
    urgency: str
    issue_summary: str
    created_at: str
    status: str


class HistoryBookingItem(BaseModel):
    """Single past booking for history listing."""
    booking_id: str
    request_id: str
    provider_id: str
    provider_name: str
    provider_phone: str
    service_type: str
    status: str
    time_slot: str
    created_at: str
