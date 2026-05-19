"""Shared trace step model used across all endpoint responses."""

from pydantic import BaseModel


class TraceStep(BaseModel):
    """Single step in the agent's reasoning trace.

    Stored in Firestore inside service_requests/{request_id}.agent_trace
    and returned in API responses so Flutter can animate the "thinking" UI.
    """
    step: str
    message: str
    timestamp: str
