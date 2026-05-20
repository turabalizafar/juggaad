"""Schemas for POST /api/v1/search — provider search + ranking."""

from pydantic import BaseModel

from app.schemas.traces import TraceStep


class SearchRequest(BaseModel):
    """Input body for POST /api/v1/search.

    Frontend sends confirmed form data after user verifies/edits
    the parsed intent from /parse.
    """
    request_id: str
    service_type: str
    location_text: str
    user_lat: float
    user_lng: float
    urgency: str


class Provider(BaseModel):
    """Single provider in ranked results."""
    id: str
    name: str
    phone_number: str
    rating: float
    distance_km: float
    eta_minutes: int
    base_price: int
    available: bool
    rank_score: float
    lat: float
    lng: float
    explanation: str | None = None


class SearchResponse(BaseModel):
    """Response from POST /api/v1/search.

    Returns top 3 providers with per-provider reasoning,
    plus an overall reasoning sentence and agent trace.
    """
    request_id: str
    providers: list[Provider]
    total_found: int
    top_3_reasoning: str
    agent_trace: list[TraceStep] = []
