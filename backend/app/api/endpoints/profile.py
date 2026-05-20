"""PUT/GET /api/v1/profile — user profile (phone number) storage."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
import app.main
from app.auth.firebase_auth import get_current_user
from app.schemas.user_profile import UserProfileInput, UserProfileResponse

router = APIRouter()


@router.put("/profile", response_model=UserProfileResponse)
async def upsert_profile(
    request: UserProfileInput,
    user_id: str = Depends(get_current_user),
):
    """
    Create or update the user's profile.
    Called after Google Auth when the phone-number dialog is submitted.
    Stores the data in Firestore `users/{uid}`.
    """
    fc = app.main.firestore_client
    if not fc:
        raise HTTPException(status_code=503, detail="Database not ready")

    now = datetime.now(timezone.utc).isoformat()

    # Check if profile already exists
    existing = fc.get_document("users", user_id)

    profile_data = {
        "phone_number": request.phone_number,
        "display_name": request.display_name,
        "updated_at": now,
    }

    if existing:
        # Update existing profile
        fc.update_document("users", user_id, profile_data)
        created_at = existing.get("created_at", now)
    else:
        # Create new profile
        profile_data["created_at"] = now
        fc.add_document("users", profile_data, doc_id=user_id)
        created_at = now

    return UserProfileResponse(
        uid=user_id,
        phone_number=request.phone_number,
        display_name=request.display_name,
        created_at=created_at,
    )


@router.get("/profile", response_model=UserProfileResponse)
async def get_profile(
    user_id: str = Depends(get_current_user),
):
    """
    Retrieve the current user's profile.
    Returns 404 if the user hasn't completed onboarding (no phone saved yet).
    """
    fc = app.main.firestore_client
    if not fc:
        raise HTTPException(status_code=503, detail="Database not ready")

    doc = fc.get_document("users", user_id)
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found. Please complete onboarding.",
        )

    return UserProfileResponse(
        uid=user_id,
        phone_number=doc.get("phone_number", ""),
        display_name=doc.get("display_name"),
        created_at=doc.get("created_at", ""),
    )
