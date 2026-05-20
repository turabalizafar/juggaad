"""POST /api/v1/parse endpoint."""

import json
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
import app.main
from app.auth.firebase_auth import get_current_user
from app.schemas.parse_request import ParseInput, ParseResponse, ParsedIntent
from app.schemas.traces import TraceStep

router = APIRouter()

PROMPT_1_SYSTEM = """You are a service request parser for a home services app in Pakistan.
Extract structured information from the user's message.
Respond ONLY with valid JSON. No explanation, no markdown, no extra text.
"""

PROMPT_1_USER_TEMPLATE = """User message: "{raw_text}"

Extract and return JSON with these exact fields:
{{
  "service_type": "<one of: ac_technician, plumber, electrician, cleaner, tutor, beautician, painter, carpenter, pest_control, shifting_service, other>",
  "location_text": "<location mentioned or null>",
  "urgency": "<one of: now, today, tomorrow, flexible, null>",
  "issue_summary": "<1 sentence summary in English>",
  "language_detected": "<urdu, roman_urdu, english, mixed, null>"
}}
"""

@router.post("/parse", response_model=ParseResponse)
async def parse_request(
    request: ParseInput,
    user_id: str = Depends(get_current_user),
):
    """
    Parses a natural language service request using Gemini.
    Detects missing fields and generates a conversational response.
    Logs traces to Firestore for real-time Flutter streaming.
    """
    gc = app.main.gemini_client
    fc = app.main.firestore_client

    if not gc or not fc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Backend services not fully initialised."
        )

    # 1. Create a request_id
    request_id = f"req_{uuid.uuid4().hex[:8]}"
    now = datetime.now(timezone.utc).isoformat()

    # 2. Initialise service_request doc in Firestore
    initial_trace = [
        {
            "step": "extracting_intent",
            "message": "Reading your request...",
            "timestamp": now,
        }
    ]
    doc_data = {
        "user_id": user_id,
        "raw_text": request.raw_text,
        "status": "parsing",
        "created_at": now,
        "agent_trace": initial_trace,
    }
    fc.add_document("service_requests", doc_data, doc_id=request_id)

    # 3. Call Gemini for JSON extraction
    user_prompt = PROMPT_1_USER_TEMPLATE.format(raw_text=request.raw_text)
    
    try:
        raw_response = gc.generate(PROMPT_1_SYSTEM, user_prompt, max_tokens=300)
        # Strip potential markdown formatting (```json ... ```)
        cleaned_response = raw_response.strip()
        if cleaned_response.startswith("```json"):
            cleaned_response = cleaned_response[7:]
        if cleaned_response.startswith("```"):
            cleaned_response = cleaned_response[3:]
        if cleaned_response.endswith("```"):
            cleaned_response = cleaned_response[:-3]
        cleaned_response = cleaned_response.strip()

        parsed_json = json.loads(cleaned_response)
        
        # Pydantic validation
        intent = ParsedIntent(**parsed_json)
        
        # Replace string "null" with None
        if intent.location_text == "null": intent.location_text = None
        if intent.urgency == "null": intent.urgency = None
        
        # Deterministic fallback: issue_summary should never be null
        if not intent.issue_summary:
            intent.issue_summary = intent.service_type.replace("_", " ") + " service request"
        
    except Exception as e:
        print(f"\n[DEBUG PARSE ERROR] {e}\n")
        # Update trace with failure
        fail_now = datetime.now(timezone.utc).isoformat()
        fc.append_trace(request_id, "parse_failed", f"Failed to parse request: {e}", fail_now)
        fc.update_document("service_requests", request_id, {"status": "failed"})
        
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not understand the request. Please try again."
        )

    # 4. GPS fallback: if location_text is missing but device coords are present
    has_gps = request.user_lat is not None and request.user_lng is not None
    if not intent.location_text and has_gps:
        intent.location_text = "Current Location"

    # 5. Check for edge cases and missing fields
    missing_fields = []
    if not intent.location_text:
        missing_fields.append("location_text")
    if not intent.urgency:
        missing_fields.append("urgency")

    # 5. Deterministic AI Message Logic
    ai_message = ""
    req_status = "complete"

    if intent.service_type == "other":
        req_status = "service_not_available"
        ai_message = "Sorry, we do not offer this service yet. We support: AC repair, plumbing, electrician, cleaning, tutoring, beauty, painting, carpentry, pest control, and moving services."
        trace_step = "service_not_available"
        trace_msg = f"Service type '{intent.service_type}' is not supported."
    elif missing_fields:
        req_status = "incomplete"
        trace_step = "missing_fields"
        if "location_text" in missing_fields and "urgency" in missing_fields:
            ai_message = "Barahe meherbani apni location aur time bataen."
            trace_msg = "Location and time not specified — asking user."
        elif "location_text" in missing_fields:
            ai_message = "Barahe meherbani apni location bataen — aap kahan hain?"
            trace_msg = "Location not specified — asking user."
        elif "urgency" in missing_fields:
            ai_message = "Barahe meherbani apna time bataen."
            trace_msg = "Time not specified — asking user."
    else:
        req_status = "complete"
        trace_step = "intent_extracted"
        ai_message = f"I understand! You need a {intent.service_type.replace('_', ' ')} in {intent.location_text} {intent.urgency} for {intent.issue_summary}."
        trace_msg = f"Service: {intent.service_type}, Location: {intent.location_text}, Time: {intent.urgency}"

    # 6. Append final trace step
    trace_now = datetime.now(timezone.utc).isoformat()
    fc.append_trace(request_id, trace_step, trace_msg, trace_now)

    # 7. Update Firestore document
    update_data = {
        "status": req_status,
        "intent": intent.model_dump(),
        "missing_fields": missing_fields,
        "ai_message": ai_message,
    }
    # Store GPS coordinates if provided (for downstream /search fallback)
    if has_gps:
        update_data["user_lat"] = request.user_lat
        update_data["user_lng"] = request.user_lng
    fc.update_document("service_requests", request_id, update_data)

    # Fetch updated document to return full trace
    doc = fc.get_document("service_requests", request_id)
    agent_trace = [TraceStep(**ts) for ts in doc.get("agent_trace", [])]

    return ParseResponse(
        request_id=request_id,
        status=req_status,
        intent=intent,
        missing_fields=missing_fields,
        ai_message=ai_message,
        agent_trace=agent_trace,
    )
