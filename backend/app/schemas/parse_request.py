"""Schemas for POST /api/v1/parse — conversational intent extraction."""

from pydantic import BaseModel

from app.schemas.traces import TraceStep


class ParseInput(BaseModel):
    """Input body for POST /api/v1/parse.

    user_id comes from Firebase JWT (get_current_user dependency),
    NOT from the request body.
    """
    raw_text: str
    language_hint: str | None = None


class ParsedIntent(BaseModel):
    """Structured intent extracted by Gemini (Prompt 1 output)."""
    service_type: str
    location_text: str | None = None
    urgency: str | None = None
    issue_summary: str | None = None
    language_detected: str | None = None


class ParseResponse(BaseModel):
    """Response from POST /api/v1/parse.

    status values:
      - "complete"              → all fields present, frontend shows editable form
      - "incomplete"            → missing_fields tells what's needed, ai_message prompts user
      - "service_not_available" → service_type='other', ai_message explains
    """
    request_id: str
    status: str  # "complete" | "incomplete" | "service_not_available"
    intent: ParsedIntent
    missing_fields: list[str] = []
    ai_message: str
    agent_trace: list[TraceStep] = []
