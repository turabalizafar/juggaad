"""POST /api/v1/search endpoint."""

import math
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
import app.main
from app.auth.firebase_auth import get_current_user
from app.schemas.providers import SearchRequest, Provider, SearchResponse
from app.schemas.traces import TraceStep

router = APIRouter()

PROMPT_2_SYSTEM = """You are a helpful assistant for a home services app. Write short, friendly explanations.
Respond with one sentence only. No lists, no markdown."""

PROMPT_2_USER_TEMPLATE = """Top provider selected: {provider_name}
Rating: {rating}/5
Distance: {distance_km} km
Availability: True
Why was this provider selected over others? Write one friendly sentence."""

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great circle distance in kilometers between two points on the earth."""
    R = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

@router.post("/search", response_model=SearchResponse)
async def search_providers(
    request: SearchRequest,
    user_id: str = Depends(get_current_user),
):
    """
    Finds and ranks providers deterministically.
    Uses Maps API for true distance/ETA and Gemini for reasoning.
    """
    fc = app.main.firestore_client
    gc = app.main.gemini_client
    mc = app.main.maps_client

    if not fc or not gc or not mc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Backend services not fully initialised."
        )

    req_id = request.request_id
    now = lambda: datetime.now(timezone.utc).isoformat()

    # 1. Validate request_id exists
    doc = fc.get_document("service_requests", req_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Service request not found.")

    # 1b. Fallback: if frontend didn't send real coords, use stored GPS from /parse
    user_lat = request.user_lat
    user_lng = request.user_lng
    if user_lat == 0.0 and user_lng == 0.0:
        user_lat = doc.get("user_lat", 0.0)
        user_lng = doc.get("user_lng", 0.0)

    # 2. Fetch providers from Firestore
    fc.append_trace(
        req_id, 
        "querying_providers", 
        f"Searching for {request.service_type} near {request.location_text}...", 
        now()
    )
    all_providers = fc.query_collection("providers", "service_type", "==", request.service_type)
    
    # 2. Filter available
    available_providers = [p for p in all_providers if p.get("availability_status") is True]
    fc.append_trace(
        req_id, 
        "filtering_available", 
        f"Found {len(available_providers)} available candidates...", 
        now()
    )

    if not available_providers:
        # Update trace and return empty
        fc.append_trace(req_id, "ranking_complete", "No available providers found.", now())
        
        updated_doc = fc.get_document("service_requests", req_id) or {}
        return SearchResponse(
            request_id=req_id,
            providers=[],
            total_found=0,
            top_3_reasoning="Unfortunately, no available providers were found in your area.",
            agent_trace=[TraceStep(**ts) for ts in updated_doc.get("agent_trace", [])]
        )

    # 3. Pre-sort by straight-line distance to avoid exceeding Maps API limits (max 25)
    for p in available_providers:
        p["_straight_dist"] = haversine_distance(user_lat, user_lng, p["lat"], p["lng"])
    
    available_providers.sort(key=lambda x: x["_straight_dist"])
    top_candidates = available_providers[:25]

    # 4. Maps Distance Matrix
    fc.append_trace(
        req_id, 
        "calculating_distances", 
        f"Computing true driving routes for {len(top_candidates)} candidates...", 
        now()
    )
    destinations = [(p["lat"], p["lng"]) for p in top_candidates]
    matrix_results = mc.get_distance_matrix(user_lat, user_lng, destinations)

    # 5. Calculate Rank Score
    # Formula: 0.4 * availability + 0.3 * distance + 0.2 * rating + 0.1 * response_time
    ranked_providers = []
    for i, p in enumerate(top_candidates):
        dist_km = matrix_results[i]["distance_km"]
        eta_min = matrix_results[i]["eta_minutes"]
        
        # If Maps API failed for this route, fallback to straight-line
        if matrix_results[i]["status"] != "OK":
            dist_km = round(p["_straight_dist"], 2)
            eta_min = max(1, int(dist_km * 3)) # roughly 3 mins per km
        
        # Normalize scores (higher is better)
        dist_score = 1.0 / (1.0 + dist_km)
        rating_score = p.get("rating", 3.0) / 5.0
        response_time = p.get("response_time_minutes", 60)
        resp_score = 1.0 / (1.0 + (response_time / 60.0))
        
        rank_score = (0.4 * 1.0) + (0.3 * dist_score) + (0.2 * rating_score) + (0.1 * resp_score)
        
        ranked_providers.append({
            "id": p["id"],
            "name": p["name"],
            "phone_number": p["phone_number"],
            "rating": p.get("rating", 0.0),
            "distance_km": dist_km,
            "eta_minutes": eta_min,
            "base_price": p.get("base_price", 0),
            "available": True,
            "rank_score": round(rank_score, 3)
        })

    # Sort descending by rank score and take Top 3
    ranked_providers.sort(key=lambda x: x["rank_score"], reverse=True)
    top_3 = ranked_providers[:3]

    # 6. Gemini Explanations
    final_providers = []
    for p in top_3:
        user_prompt = PROMPT_2_USER_TEMPLATE.format(
            provider_name=p["name"],
            rating=p["rating"],
            distance_km=p["distance_km"]
        )
        try:
            explanation = gc.generate(PROMPT_2_SYSTEM, user_prompt, max_tokens=80).strip()
        except Exception:
            explanation = f"{p['name']} is a highly rated provider near you."
        
        p_obj = Provider(
            **p,
            explanation=explanation
        )
        final_providers.append(p_obj)

    # 7. Finalise response
    winner_name = final_providers[0].name if final_providers else "none"
    winner_dist = final_providers[0].distance_km if final_providers else 0.0
    
    fc.append_trace(
        req_id, 
        "ranking_complete", 
        f"Top 3 selected — closest: {winner_name} ({winner_dist} km)", 
        now()
    )

    updated_doc = fc.get_document("service_requests", req_id) or {}
    agent_trace = [TraceStep(**ts) for ts in updated_doc.get("agent_trace", [])]

    return SearchResponse(
        request_id=req_id,
        providers=final_providers,
        total_found=len(available_providers),
        top_3_reasoning="These providers were selected based on their proximity, high ratings, and availability.",
        agent_trace=agent_trace
    )
