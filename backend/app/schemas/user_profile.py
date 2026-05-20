"""Schemas for user profile (phone number storage after Google Auth)."""

from pydantic import BaseModel


class UserProfileInput(BaseModel):
    """Input body for PUT /api/v1/profile."""
    phone_number: str          # "+923001234567"
    display_name: str | None = None


class UserProfileResponse(BaseModel):
    """Response from GET/PUT /api/v1/profile."""
    uid: str
    phone_number: str
    display_name: str | None = None
    created_at: str
