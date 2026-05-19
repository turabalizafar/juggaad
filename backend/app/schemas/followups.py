"""Schemas for POST /api/v1/followups/reminder — matches docs/api_design.md."""

from pydantic import BaseModel


class FollowupRequest(BaseModel):
    """Input body for /followups/reminder."""
    booking_id: str
    trigger: str  # pre_arrival | completed | follow_up_review


class FollowupResponse(BaseModel):
    """Response from /followups/reminder."""
    message: str
    send_at: str
