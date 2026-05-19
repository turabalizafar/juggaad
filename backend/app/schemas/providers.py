"""Schemas for POST /api/v1/providers/search — matches docs/api_design.md."""

from pydantic import BaseModel


class ProviderSearchRequest(BaseModel):
    """Input body for /providers/search."""
    request_id: str
    service_type: str
    user_lat: float
    user_lng: float
    urgency: str


class Provider(BaseModel):
    """Single provider in ranked results."""
    id: str
    name: str
    rating: float
    distance_km: float
    eta_minutes: int
    base_price: int
    available: bool
    rank_score: float
    explanation: str | None = None


class ProviderSearchResponse(BaseModel):
    """Response from /providers/search."""
    providers: list[Provider]
    total_found: int
