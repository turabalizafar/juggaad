# Architecture — AISeekho Challenge 2: Service Orchestrator

## System Summary

Intelligent service coordination app. User types/speaks request → AI parses intent → backend finds/ranks providers → booking simulated → follow-up generated.

AI = language + explanation only. Backend = logic, math, decisions. Maps = geocoding + distance. Flutter = display.

---

## High-Level Architecture

```
Flutter Mobile App
        ↓  REST/JSON
FastAPI Backend (orchestrator)
  ├── /parse-request     → Gemini API (intent extraction)
  ├── /providers/search  → Provider Matching Service (deterministic)
  ├── /bookings/create   → Booking Simulation Service
  ├── /followups/        → Notification/Reminder Service
  ├── /traces/           → Trace Logger
  └── Firestore DB
        ├── users
        ├── providers
        ├── service_requests
        ├── bookings
        └── traces
```

---

## Layer Breakdown

### Flutter (Mobile)
- State: Riverpod
- HTTP: Dio
- Maps: google_maps_flutter SDK
- Auth: Firebase Auth SDK
- Screens: 7 core screens (see UI plan)

### FastAPI (Backend Orchestrator)
- Python 3.11+
- Modular: `api/`, `agents/`, `services/`, `schemas/`, `models/`, `utils/`
- CORS enabled for mobile
- Structured logging via Python `logging` + trace service

### AI Layer (Gemini / Vertex AI)
**Only used for:**
1. Intent extraction from raw user text (→ structured JSON)
2. Provider recommendation explanation (natural language reason)
3. Follow-up message generation (reminders, completion prompts)

**NOT used for:**
- Distance calculation
- Ranking math
- Booking state logic
- Database operations

### Google Maps Platform
- Geocoding API: text location → lat/lng
- Distance Matrix API: provider distance + ETA
- Maps SDK (Flutter): show providers on map
- Nearby Search (Places): optional real provider layer

### Database: Firestore
- Chosen for: Firebase Auth integration, flexible schema, fast iteration
- Alternative: PostgreSQL if team prefers relational

### Auth: Firebase Auth
- Phone/email login
- JWT token passed to FastAPI on each request

### Hosting
- Backend: Cloud Run (containerized FastAPI) or Render
- Firestore: managed by Google
- Frontend: built APK for demo, or Firebase Hosting for web build

---

## Module Roles

| Module | Job | AI or Deterministic? |
|--------|-----|----------------------|
| Request Agent | Parse text → JSON intent | AI (Gemini) |
| Provider Service | Filter + rank candidates | Deterministic |
| Booking Service | Create booking record | Deterministic |
| Maps Service | Geocode + distance | Deterministic (Maps API) |
| Explanation Service | Generate ranking reason | AI (Gemini) |
| Notification Service | Reminder/follow-up text | AI (Gemini, short prompt) |
| Trace Service | Log every step | Deterministic |

---

## Key Design Principles

1. Frontend displays state — never invents it
2. Backend owns all business logic
3. DB is single source of truth
4. AI interprets and explains — backend decides
5. Mock provider data seeded at start — always enough results
6. One narrow demo lane: AC Technician (hero category)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Gemini token cost | Small focused prompts, strict max_tokens |
| Gemini hallucination | Only used for NL tasks, never for data decisions |
| Maps API quota | Cache geocode results in Firestore |
| Scope creep | Lock to AC tech demo lane only |
| Flutter complexity | Pre-built screens via Stitch, simple state |
| Time overrun | Mock data ready Day 1, backend before UI |
