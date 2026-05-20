"""POST /api/v1/book and GET /api/v1/booking/{id} endpoints."""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
import app.main
from app.auth.firebase_auth import get_current_user
from app.schemas.bookings import BookRequest, BookResponse, BookingStatusResponse
from app.schemas.traces import TraceStep

router = APIRouter()

@router.post("/book", response_model=BookResponse)
async def create_booking(
    request: BookRequest,
    user_id: str = Depends(get_current_user),
):
    """
    Creates a simulated booking record.
    Returns tracking ID, ETA, and final confirmation.
    """
    fc = app.main.firestore_client
    if not fc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Backend services not fully initialised."
        )

    req_id = request.request_id
    now = lambda: datetime.now(timezone.utc).isoformat()

    # 1. Fetch provider details
    provider = fc.get_document("providers", request.provider_id)
    if not provider:
        fc.append_trace(req_id, "booking_failed", "Provider not found", now())
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Provider not found")

    provider_name = provider.get("name", "Unknown Provider")
    provider_phone = provider.get("phone_number", "+923266142848")

    # 1b. Resolve user phone number: use provided value, or fall back to profile
    user_phone = request.user_phone_number
    if not user_phone:
        profile = fc.get_document("users", user_id)
        user_phone = profile.get("phone_number", "") if profile else ""
    
    # 2. Add trace to service request
    fc.append_trace(req_id, "creating_booking", f"Reserving slot with {provider_name}...", now())

    # 3. Create booking record
    booking_id = f"bkg_{uuid.uuid4().hex[:8]}"
    tracking_id = f"TRK-{datetime.now(timezone.utc).strftime('%Y-%m%d')}-{uuid.uuid4().hex[:4].upper()}"
    
    # Use the real ETA from /search (passed forward by frontend), not a fake number
    eta_minutes = request.agreed_eta_minutes

    booking_data = {
        "user_id": user_id,
        "request_id": req_id,
        "provider_id": request.provider_id,
        "provider_name": provider_name,
        "provider_phone": provider_phone,
        "user_phone_number": user_phone,
        "time_slot": request.time_slot,
        "tracking_id": tracking_id,
        "status": "confirmed",
        "eta_minutes": eta_minutes,
        "created_at": now(),
        "service_type": provider.get("service_type", "unknown")
    }
    
    fc.add_document("bookings", booking_data, doc_id=booking_id)

    # 4. Finalise trace
    confirmation_text = f"Booking confirmed! {provider_name} will arrive in ~{eta_minutes} mins."
    fc.append_trace(req_id, "booking_confirmed", f"Booking {tracking_id} confirmed — ETA {eta_minutes} mins", now())

    # 5. Fetch updated traces
    doc = fc.get_document("service_requests", req_id)
    agent_trace = [TraceStep(**ts) for ts in doc.get("agent_trace", [])]

    return BookResponse(
        booking_id=booking_id,
        tracking_id=tracking_id,
        status="confirmed",
        provider_name=provider_name,
        provider_phone=provider_phone,
        eta_minutes=eta_minutes,
        confirmation_text=confirmation_text,
        simulated=True,
        agent_trace=agent_trace
    )


@router.get("/booking/{booking_id}", response_model=BookingStatusResponse)
async def get_booking_status(
    booking_id: str,
    user_id: str = Depends(get_current_user),
):
    """Fetch booking state for tracking screen."""
    fc = app.main.firestore_client
    if not fc:
        raise HTTPException(status_code=503, detail="Database not ready")

    booking = fc.get_document("bookings", booking_id)
    if not booking or booking.get("user_id") != user_id:
        raise HTTPException(status_code=404, detail="Booking not found")

    return BookingStatusResponse(
        booking_id=booking_id,
        tracking_id=booking.get("tracking_id", "UNKNOWN"),
        status=booking.get("status", "en_route"),
        provider_name=booking.get("provider_name", "Unknown"),
        provider_phone=booking.get("provider_phone", ""),
        eta_minutes=booking.get("eta_minutes", 0),
        last_updated=datetime.now(timezone.utc).isoformat()
    )
