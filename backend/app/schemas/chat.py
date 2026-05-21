"""Schemas for POST /api/v1/chat — multi-turn conversational intent extraction."""

from pydantic import BaseModel
from app.schemas.traces import TraceStep


class ChatMessageInput(BaseModel):
    """A single message in the conversation history."""
    role: str   # "user" or "assistant"
    content: str


class ChatInput(BaseModel):
    """Input body for POST /api/v1/chat."""
    messages: list[ChatMessageInput]
    user_lat: float | None = None
    user_lng: float | None = None


class ChatParsedIntent(BaseModel):
    """Structured intent extracted by Gemini from conversation."""
    service_type: str
    location_text: str | None = None
    urgency: str | None = None
    issue_summary: str | None = None
    language_detected: str | None = None


class ChatResponse(BaseModel):
    """Response from POST /api/v1/chat.

    status values:
      - "complete"              → all fields present, frontend shows editable form
      - "incomplete"            → ai_message has the conversational reply
      - "service_not_available" → service_type='other', ai_message explains
      - "off_topic"             → user is chatting about non-service topics
    """
    request_id: str
    status: str
    intent: ChatParsedIntent
    missing_fields: list[str] = []
    ai_message: str
    agent_trace: list[TraceStep] = []
