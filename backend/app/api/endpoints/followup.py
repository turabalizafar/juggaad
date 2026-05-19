"""POST /api/v1/followup endpoint."""

from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
import app.main
from app.auth.firebase_auth import get_current_user
from app.schemas.followups import FollowupRequest, FollowupResponse

router = APIRouter()

PROMPT_3_SYSTEM = """You generate short, friendly SMS-style reminders for a home services app in Pakistan.
One sentence. Casual, warm tone. In English."""

PROMPT_3_USER_TEMPLATE = """Trigger: {trigger}
Provider name: {provider_name}
ETA minutes: {eta_minutes}
Service: {service_type}

Write one short reminder message for this trigger."""

@router.post("/followup", response_model=FollowupResponse)
async def generate_followup(
    request: FollowupRequest,
    user_id: str = Depends(get_current_user),
):
    """Generates an AI reminder/follow-up message using Gemini."""
    fc = app.main.firestore_client
    gc = app.main.gemini_client

    if not fc or not gc:
        raise HTTPException(status_code=503, detail="Backend services not fully initialised.")

    # 1. Fetch booking to get provider info
    booking = fc.get_document("bookings", request.booking_id)
    if not booking or booking.get("user_id") != user_id:
        raise HTTPException(status_code=404, detail="Booking not found")

    provider_name = booking.get("provider_name", "your provider")
    eta_minutes = booking.get("eta_minutes", 10)
    service_type = booking.get("service_type", "service")

    # 2. Call Gemini
    user_prompt = PROMPT_3_USER_TEMPLATE.format(
        trigger=request.trigger,
        provider_name=provider_name,
        eta_minutes=eta_minutes,
        service_type=service_type
    )

    try:
        message = gc.generate(PROMPT_3_SYSTEM, user_prompt, max_tokens=60).strip()
    except Exception:
        # Fallback if Gemini fails
        if request.trigger == "pre_arrival":
            message = f"{provider_name} is arriving in ~{eta_minutes} mins."
        elif request.trigger == "completed":
            message = f"Your {service_type} is complete! Don't forget to rate {provider_name}."
        else:
            message = f"Hope everything went well with {provider_name}!"

    # 3. Compute fake "send_at" time
    now_ts = datetime.now(timezone.utc)
    send_at = (now_ts + timedelta(minutes=1)).isoformat()

    # 4. Append trace logging
    request_id = booking.get("request_id")
    if request_id:
        fc.append_trace(
            request_id,
            "generating_followup",
            f"Sent follow-up for trigger: {request.trigger}",
            now_ts.isoformat()
        )

    return FollowupResponse(message=message, send_at=send_at)
