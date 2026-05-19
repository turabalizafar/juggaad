"""GET /api/v1/history/requests and /bookings endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
import app.main
from app.auth.firebase_auth import get_current_user
from app.schemas.history import HistoryRequestItem, HistoryBookingItem

router = APIRouter()

@router.get("/history/requests", response_model=dict[str, list[HistoryRequestItem]])
async def get_request_history(
    user_id: str = Depends(get_current_user),
):
    """Fetch past service requests for the user."""
    fc = app.main.firestore_client
    if not fc:
        raise HTTPException(status_code=503, detail="Database not ready")

    docs = fc.query_collection("service_requests", "user_id", "==", user_id)
    
    # Sort descending by created_at in python since query_collection doesn't do complex sorting yet
    docs.sort(key=lambda x: x.get("created_at", ""), reverse=True)

    requests_list = []
    for doc in docs:
        intent = doc.get("intent", {})
        requests_list.append(
            HistoryRequestItem(
                request_id=doc["id"],
                service_type=intent.get("service_type", "unknown"),
                location_text=intent.get("location_text"),
                urgency=intent.get("urgency", "flexible"),
                issue_summary=intent.get("issue_summary", "No details"),
                created_at=doc.get("created_at", ""),
                status=doc.get("status", "unknown")
            )
        )

    return {"requests": requests_list}


@router.get("/history/bookings", response_model=dict[str, list[HistoryBookingItem]])
async def get_booking_history(
    user_id: str = Depends(get_current_user),
):
    """Fetch past bookings for the user (includes provider phone for Call Again)."""
    fc = app.main.firestore_client
    if not fc:
        raise HTTPException(status_code=503, detail="Database not ready")

    docs = fc.query_collection("bookings", "user_id", "==", user_id)
    
    # Sort descending by created_at
    docs.sort(key=lambda x: x.get("created_at", ""), reverse=True)

    bookings_list = []
    for doc in docs:
        bookings_list.append(
            HistoryBookingItem(
                booking_id=doc["id"],
                request_id=doc.get("request_id", ""),
                provider_id=doc.get("provider_id", ""),
                provider_name=doc.get("provider_name", "Unknown"),
                provider_phone=doc.get("provider_phone", "+923266142848"),
                service_type=doc.get("service_type", "unknown"),
                status=doc.get("status", "unknown"),
                time_slot=doc.get("time_slot", ""),
                created_at=doc.get("created_at", "")
            )
        )

    return {"bookings": bookings_list}
