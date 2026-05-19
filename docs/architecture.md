# Architecture — AISeekho Challenge 2: Service Orchestrator

## System Summary

Intelligent service coordination app. User types request → AI parses intent → backend finds/ranks providers → booking simulated → follow-up generated. Real-time agent trace logs streamed to Flutter via Firestore.

AI = language + explanation only. Backend = logic, math, decisions, ai_message generation. Maps = distance + ETA. Flutter = display + real-time trace animation.

---

## High-Level Architecture

```
Flutter Mobile App (StreamBuilder on Firestore)
        ↓  REST/JSON + Firebase Auth JWT
FastAPI Backend (orchestrator)
  ├── /parse             → Gemini API (intent extraction) + deterministic ai_message
  ├── /search            → Provider Matching Service (deterministic) + Maps Distance Matrix
  ├── /book              → Booking Simulation Service
  ├── /followup          → Notification/Reminder Service (Gemini Prompt 3)
  ├── /booking/{id}      → Booking status for tracking
  ├── /history/          → Past requests & bookings (Call Again)
  └── Firestore DB
        ├── users
        ├── providers              (300 seeded, includes phone_number)
        ├── service_requests       (includes agent_trace[] for real-time streaming)
        └── bookings               (includes user_phone, provider_phone, tracking_id)
```

---

## Conversational Multi-Step Flow

```
User types Roman Urdu request
        ↓
POST /parse → Gemini extracts JSON intent → Python checks missing fields
        ↓
  ┌─ status: "complete"        → Frontend shows editable form
  ├─ status: "incomplete"      → Frontend shows ai_message, prompts for missing field
  └─ status: "service_not_available" → Frontend shows error message
        ↓ (user confirms/edits form)
POST /search → Firestore query + Maps Distance Matrix + Gemini explanation
        ↓
  Frontend shows top 3 providers with stats, rating, phone, reasoning
        ↓ (user picks provider)
POST /book → Firestore booking created, tracking_id generated
        ↓
  Frontend shows booking confirmation + ETA
        ↓ (optional)
  Track provider on map / Rate provider / Home
```

---

## Layer Breakdown

### Flutter (Mobile)
- State: Riverpod
- HTTP: Dio
- Maps: google_maps_flutter SDK
- Auth: Firebase Auth SDK
- Real-time: Firestore StreamBuilder on service_requests/{id} for agent trace animation
- Screens: 7 core screens (see UI plan)

### FastAPI (Backend Orchestrator)
- Python 3.11+
- Modular: `api/`, `services/`, `schemas/`, `auth/`
- CORS enabled for mobile
- Agent traces written to Firestore (arrayUnion) for real-time Flutter streaming

### AI Layer (Gemini / Vertex AI)
**Only used for:**
1. Intent extraction from raw user text → structured JSON (Prompt 1)
2. Provider recommendation explanation → one sentence (Prompt 2)
3. Follow-up message generation → reminders (Prompt 3)

**NOT used for:**
- ai_message / missing_fields logic (deterministic Python)
- Distance calculation (Maps API)
- Ranking math (backend formula)
- Booking state logic (backend)
- Error messages (hardcoded strings)

### Google Maps Platform
- Distance Matrix API: provider distance + ETA
- Maps SDK (Flutter): show providers on map, tracking view

### Database: Firestore
- Real-time database for Flutter StreamBuilder
- Agent traces stored in service_requests documents
- Chosen for: Firebase Auth integration, real-time streaming, flexible schema

### Auth: Firebase Auth
- Phone/email login
- JWT token passed to FastAPI on each request
- user_id extracted from token, NOT from request body

---

## Module Roles

| Module | Job | AI or Deterministic? |
|--------|-----|----------------------|
| Request Parser | Parse text → JSON intent | AI (Gemini Prompt 1) |
| Missing Field Detector | Check for nulls, generate ai_message | Deterministic (Python) |
| Provider Service | Filter + rank candidates | Deterministic |
| Booking Service | Create booking record | Deterministic |
| Maps Service | Distance + ETA | Deterministic (Maps API) |
| Explanation Service | Generate ranking reason | AI (Gemini Prompt 2) |
| Notification Service | Reminder/follow-up text | AI (Gemini Prompt 3) |
| Trace Service | Log every step to Firestore | Deterministic |

---

## Key Design Principles

1. Frontend displays state — never invents it
2. Backend owns all business logic
3. DB is single source of truth
4. AI interprets and explains — backend decides
5. One job per prompt — never mix JSON extraction with creative writing
6. ai_message is deterministic Python, not AI-generated
7. Agent traces stored in Firestore for real-time Flutter streaming
8. Multiple service categories (10 types) across 18 Pakistani cities (3 clusters)
9. Provider phone_number included in all provider-facing responses
10. No demo button, no guest flow — manual auth only

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------| 
| Gemini token cost | Small focused prompts, strict max_tokens |
| Gemini hallucination | Only used for NL tasks, never for data decisions |
| Maps API quota | Cache geocode results, limit to cluster-local queries |
| JSON parse failure | Strict Prompt 1 with "ONLY valid JSON", Pydantic validation |
| Scope creep | 10 categories seeded, but flow works for any |
| Flutter complexity | StreamBuilder on Firestore for real-time, simple state |
| Time overrun | Mock data ready, backend before UI |
