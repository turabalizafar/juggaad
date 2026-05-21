"""POST /api/v1/chat — multi-turn conversational intent extraction."""

import json
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
import app.main
from app.auth.firebase_auth import get_current_user
from app.schemas.chat import ChatInput, ChatResponse, ChatParsedIntent
from app.schemas.traces import TraceStep

router = APIRouter()

# ── System prompt: instructs Gemini to be a focused service assistant ──────
CHAT_SYSTEM_PROMPT = """You are a service request assistant for a home services app called "Jugaad" in Pakistan.

Your ONLY purpose is to help users request home services (plumber, electrician, AC repair, cleaner, tutor, beautician, painter, carpenter, pest control, shifting/moving).

RULES:
1. If the user talks about ANYTHING other than requesting a service (e.g. general chat, jokes, questions about weather, politics, personal matters), reply ONLY with:
   {"status": "off_topic", "ai_message": "Main sirf service requests mein madad kar sakta hoon! Batayein, kya service chahiye?"}

2. Analyse the FULL conversation history to understand context. If a user previously said they need a plumber and now says "kal 10 bajy", understand this as providing the time for the SAME request.

3. You need to extract these fields from the conversation:
   - service_type: one of [ac_technician, plumber, electrician, cleaner, tutor, beautician, painter, carpenter, pest_control, shifting_service, other]
   - location_text: where the service is needed (IMPORTANT: see rule 9 and 10 below)
   - urgency: one of [now, today, tomorrow, flexible] or a specific time description
   - issue_summary: 1 sentence summary in English

4. If ALL fields (service_type, location_text, urgency) are present across the conversation, respond with:
   {"status": "complete", "intent": {"service_type": "...", "location_text": "...", "urgency": "...", "issue_summary": "...", "language_detected": "..."}}

5. If some fields are still missing, respond with:
   {"status": "incomplete", "missing_fields": ["field1", "field2"], "ai_message": "<conversational reply asking for missing info IN THE SAME LANGUAGE the user is using>"}

6. If service_type is "other" (not in our supported list), respond with:
   {"status": "service_not_available", "ai_message": "Sorry, we do not offer this service yet. We support: AC repair, plumbing, electrician, cleaning, tutoring, beauty, painting, carpentry, pest control, and moving services."}

7. Reply in the SAME language the user is using (Urdu, Roman Urdu, English, or mixed).

8. Respond ONLY with valid JSON. No explanation, no markdown, no extra text.

9. If the user asks for MULTIPLE services or MULTIPLE locations in one message, do NOT try to extract multiple intents. Instead respond with:
   {"status": "incomplete", "missing_fields": [], "ai_message": "Ek waqt mein sirf ek service request karein. Pehle batayein kaunsi service chahiye aur kahan?"}

10. LOCATION HANDLING (CRITICAL):
    - If the user says "near me", "mere ghar", "mere paas", "my location", "my home", "yahan", "idhar" or any variation meaning their current location, set location_text to exactly "__CURRENT_LOCATION__".
    - For ALL other locations (named places like "DHA Lahore", "Mandi Bahauddin", "Gulberg"), set location_text to the actual place name as the user described it.
    - NEVER set location_text to a generic value. Use either the exact place name or "__CURRENT_LOCATION__".
"""


@router.post("/chat", response_model=ChatResponse)
async def chat_parse(
    request: ChatInput,
    user_id: str = Depends(get_current_user),
):
    """
    Multi-turn conversational intent extraction.
    Receives the full chat history and uses Gemini to either:
    - Extract a complete structured intent
    - Reply conversationally asking for missing fields
    - Reject off-topic messages
    """
    gc = app.main.gemini_client
    fc = app.main.firestore_client

    if not gc or not fc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Backend services not fully initialised."
        )

    # Limit to last 8 messages to control token usage
    recent_messages = request.messages[-8:] if len(request.messages) > 8 else request.messages

    if not recent_messages:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one message is required."
        )

    # Build multi-turn conversation string for Gemini
    conversation_text = ""
    for msg in recent_messages:
        role_label = "User" if msg.role == "user" else "Assistant"
        conversation_text += f"{role_label}: {msg.content}\n"

    user_prompt = f"""Conversation history:
{conversation_text}

Based on the FULL conversation above, extract the service request intent or ask for missing information.
Respond with JSON only."""

    request_id = f"req_{uuid.uuid4().hex[:8]}"
    now = datetime.now(timezone.utc).isoformat()

    # Trace setup
    initial_trace = [{
        "step": "chat_processing",
        "message": "Analyzing conversation...",
        "timestamp": now,
    }]
    doc_data = {
        "user_id": user_id,
        "raw_text": recent_messages[-1].content,
        "status": "parsing",
        "created_at": now,
        "agent_trace": initial_trace,
    }
    fc.add_document("service_requests", doc_data, doc_id=request_id)

    try:
        raw_response = gc.generate(CHAT_SYSTEM_PROMPT, user_prompt, max_tokens=400)

        # Strip markdown formatting
        cleaned = raw_response.strip()
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        if cleaned.startswith("```"):
            cleaned = cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]
        cleaned = cleaned.strip()

        parsed = json.loads(cleaned)

    except Exception as e:
        print(f"\n[DEBUG CHAT PARSE ERROR] {e}\n")
        fc.append_trace(request_id, "chat_failed", f"Failed: {e}", now)
        fc.update_document("service_requests", request_id, {"status": "failed"})
        return ChatResponse(
            request_id=request_id,
            status="incomplete",
            intent=ChatParsedIntent(service_type="unknown"),
            missing_fields=[],
            ai_message="Sorry, mujhe samajh nahi aaya. Kripya dobara try karein ya apni request alag tareeqay se likhein.",
            agent_trace=[],
        )

    # Determine response type
    resp_status = parsed.get("status", "incomplete")

    # Handle off_topic
    if resp_status == "off_topic":
        ai_message = parsed.get("ai_message", "Main sirf service requests mein madad kar sakta hoon!")
        fc.append_trace(request_id, "off_topic", "User sent off-topic message", now)
        fc.update_document("service_requests", request_id, {"status": "off_topic"})
        return ChatResponse(
            request_id=request_id,
            status="off_topic",
            intent=ChatParsedIntent(service_type="unknown"),
            missing_fields=[],
            ai_message=ai_message,
            agent_trace=[],
        )

    # Handle service_not_available
    if resp_status == "service_not_available":
        ai_message = parsed.get("ai_message", "Sorry, we do not offer this service yet.")
        fc.append_trace(request_id, "service_not_available", ai_message, now)
        fc.update_document("service_requests", request_id, {"status": "service_not_available"})
        return ChatResponse(
            request_id=request_id,
            status="service_not_available",
            intent=ChatParsedIntent(service_type="other"),
            missing_fields=[],
            ai_message=ai_message,
            agent_trace=[],
        )

    # Handle incomplete
    if resp_status == "incomplete":
        missing = parsed.get("missing_fields", [])
        ai_message = parsed.get("ai_message", "Kuch aur details chahiye.")
        fc.append_trace(request_id, "missing_fields", f"Missing: {missing}", now)
        fc.update_document("service_requests", request_id, {
            "status": "incomplete",
            "missing_fields": missing,
            "ai_message": ai_message,
        })
        return ChatResponse(
            request_id=request_id,
            status="incomplete",
            intent=ChatParsedIntent(service_type="unknown"),
            missing_fields=missing,
            ai_message=ai_message,
            agent_trace=[],
        )

    # Handle complete
    intent_data = parsed.get("intent", parsed)
    intent = ChatParsedIntent(
        service_type=intent_data.get("service_type", "unknown"),
        location_text=intent_data.get("location_text"),
        urgency=intent_data.get("urgency"),
        issue_summary=intent_data.get("issue_summary", "Service request"),
        language_detected=intent_data.get("language_detected", "unknown"),
    )

    # Replace string "null" with None
    if intent.location_text == "null":
        intent.location_text = None
    if intent.urgency == "null":
        intent.urgency = None

    # Fallback issue_summary
    if not intent.issue_summary:
        intent.issue_summary = intent.service_type.replace("_", " ") + " service request"

    # GPS fallback
    has_gps = request.user_lat is not None and request.user_lng is not None
    if not intent.location_text and has_gps:
        intent.location_text = "Current Location"

    # Final check for truly complete
    missing_fields = []
    if not intent.location_text:
        missing_fields.append("location_text")
    if not intent.urgency:
        missing_fields.append("urgency")

    if missing_fields:
        # Gemini said complete but fields are actually empty — ask again
        if "location_text" in missing_fields and "urgency" in missing_fields:
            ai_message = "Barahe meherbani apni location aur time bataen."
        elif "location_text" in missing_fields:
            ai_message = "Barahe meherbani apni location bataen — aap kahan hain?"
        elif "urgency" in missing_fields:
            ai_message = "Barahe meherbani apna time bataen."
        else:
            ai_message = "Kuch aur details chahiye."

        fc.append_trace(request_id, "missing_fields", f"Missing: {missing_fields}", now)
        fc.update_document("service_requests", request_id, {
            "status": "incomplete",
            "missing_fields": missing_fields,
            "ai_message": ai_message,
        })
        return ChatResponse(
            request_id=request_id,
            status="incomplete",
            intent=intent,
            missing_fields=missing_fields,
            ai_message=ai_message,
            agent_trace=[],
        )

    # Truly complete
    ai_message = f"Got it! Let me find the best {intent.service_type.replace('_', ' ')} near {intent.location_text} for you right now."
    trace_msg = f"Service: {intent.service_type}, Location: {intent.location_text}, Time: {intent.urgency}"
    fc.append_trace(request_id, "intent_extracted", trace_msg, now)

    update_data = {
        "status": "complete",
        "intent": intent.model_dump(),
        "missing_fields": [],
        "ai_message": ai_message,
    }
    if has_gps:
        update_data["user_lat"] = request.user_lat
        update_data["user_lng"] = request.user_lng
    fc.update_document("service_requests", request_id, update_data)

    doc = fc.get_document("service_requests", request_id)
    agent_trace = [TraceStep(**ts) for ts in doc.get("agent_trace", [])]

    return ChatResponse(
        request_id=request_id,
        status="complete",
        intent=intent,
        missing_fields=[],
        ai_message=ai_message,
        agent_trace=agent_trace,
    )
