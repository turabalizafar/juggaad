"""Schemas for POST /api/v1/parse-request — matches docs/api_design.md."""

from pydantic import BaseModel


class ParseRequestInput(BaseModel):
    """Input body for /parse-request."""
    user_id: str
    raw_text: str
    language_hint: str | None = None


class ParseRequestResponse(BaseModel):
    """Response from /parse-request after Gemini intent extraction."""
    request_id: str
    service_type: str
    location_text: str | None = None
    urgency: str
    issue_summary: str
    parsed_ok: bool
