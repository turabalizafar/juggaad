# Critical Architecture Realignment — Step 2.5

Three structural changes to align backend with the conversational UI flow and resolve all doc/code conflicts before building endpoint logic.

---

## Change 1: Delete All Demo/Guest References

**Files with stale `/demo/run` or guest flow references to clean:**

| File | What to remove/update |
|------|----------------------|
| `docs/api_design.md` | Already has `/demo/run` at L169–181 (old version not yet cleaned) |
| `docs/tasks.md` | Task 2.5 still references `/demo/run` at L70–74, Task 3.4 references demo button |
| `docs/architecture.md` | L101 still says "One narrow demo lane: AC Technician" |
| `docs/prompts.md` | Clean — no demo refs |
| Backend code | No demo endpoint code exists yet — nothing to delete |

---

## Change 2: Trace Logging IN Firestore (Reversal)

**Previous rule:** "Do not store traces in Firestore"  
**New rule:** Traces ARE stored in Firestore inside `service_requests/{request_id}` documents so Flutter can use `StreamBuilder` for real-time "thinking" animation.

### Trace Storage Design

Instead of a separate `traces` collection, each `service_requests` document contains an `agent_trace` array that the backend **appends to incrementally** as it processes:

```json
// Firestore: service_requests/{request_id}
{
  "user_id": "uid_abc",
  "raw_text": "mujhe AC theek karwana hai DHA mein",
  "status": "parsing",        // parsing → parsed → searching → matched → booking → complete
  "created_at": "...",
  "intent": { ... },           // filled after /parse
  "providers": [ ... ],        // filled after /search
  "booking": { ... },          // filled after /book
  "agent_trace": [
    {"step": "extracting_intent", "message": "Reading user request in Roman Urdu...", "timestamp": "..."},
    {"step": "intent_extracted", "message": "Service: AC Technician, Location: DHA, Time: not specified", "timestamp": "..."},
    {"step": "missing_fields", "message": "Time not specified — asking user", "timestamp": "..."},
    {"step": "querying_providers", "message": "Searching for AC technicians near DHA Lahore...", "timestamp": "..."},
    {"step": "calculating_distances", "message": "Computing distances for 12 available providers...", "timestamp": "..."},
    {"step": "ranking_complete", "message": "Top 3 providers selected based on distance, rating, and availability", "timestamp": "..."},
    {"step": "booking_created", "message": "Booking confirmed with Usman AC Repair — ETA 18 mins", "timestamp": "..."}
  ]
}
```

**Flutter listens** to `service_requests/{request_id}` with a Firestore snapshot listener → as `agent_trace` grows, the UI animates each new step in real time.

### Code Changes Required

#### [MODIFY] `app/services/firestore_client.py`
- Remove the "NO trace logging" comment
- Add `append_trace(request_id, step, message)` method that does an array union on the `agent_trace` field

---

## Change 3: Multi-Endpoint Conversational Flow

### Old endpoints → New endpoints

| Old | New | What changed |
|-----|-----|-------------|
| `POST /api/v1/parse-request` | `POST /api/v1/parse` | Shorter name + returns `missing_fields` + `ai_message` for conversational flow |
| `POST /api/v1/providers/search` | `POST /api/v1/search` | Returns top 3 only + per-provider reasoning |
| `POST /api/v1/bookings/create` | `POST /api/v1/book` | Shorter name, generates tracking_id |
| `GET /api/v1/bookings/{id}` | `GET /api/v1/booking/{id}` | Kept for tracking screen |
| `POST /api/v1/followups/reminder` | `POST /api/v1/followup` | Shortened |
| `GET /api/v1/history/requests` | Kept | No change |
| `GET /api/v1/history/bookings` | Kept | No change |
| `POST /api/v1/demo/run` | **DELETED** | |
| `GET /api/v1/traces/{id}` | **DELETED** (traces are embedded in service_requests) | |

### New `/api/v1/parse` — Full JSON Schema

This is what the frontend team needs **right now**:

**Request:**
```json
{
  "raw_text": "mujhe aaj AC theek karwana hai, main DHA Lahore mein hoon",
  "language_hint": "roman_urdu"
}
```
> `user_id` extracted from Firebase JWT — not in body.

**Response (success — all fields present):**
```json
{
  "request_id": "req_a1b2c3",
  "status": "complete",
  "intent": {
    "service_type": "ac_technician",
    "location_text": "DHA Lahore",
    "urgency": "today",
    "issue_summary": "AC repair needed today",
    "language_detected": "roman_urdu"
  },
  "missing_fields": [],
  "ai_message": "I understand! You need an AC technician in DHA Lahore today for AC repair.",
  "agent_trace": [
    {"step": "extracting_intent", "message": "Reading your request...", "timestamp": "2026-05-20T02:15:00Z"},
    {"step": "intent_extracted", "message": "Service: AC Technician, Location: DHA Lahore, Time: Today", "timestamp": "2026-05-20T02:15:01Z"}
  ]
}
```

**Response (incomplete — missing location):**
```json
{
  "request_id": "req_d4e5f6",
  "status": "incomplete",
  "intent": {
    "service_type": "ac_technician",
    "location_text": null,
    "urgency": "today",
    "issue_summary": "AC repair needed today",
    "language_detected": "roman_urdu"
  },
  "missing_fields": ["location_text"],
  "ai_message": "Barahe meherbani apni location bataen — aap kahan hain?",
  "agent_trace": [
    {"step": "extracting_intent", "message": "Reading your request...", "timestamp": "..."},
    {"step": "missing_fields", "message": "Location not specified — asking user", "timestamp": "..."}
  ]
}
```

**Response (service not available):**
```json
{
  "request_id": "req_g7h8i9",
  "status": "service_not_available",
  "intent": {
    "service_type": "other",
    "location_text": "G-13 Islamabad",
    "urgency": "today",
    "issue_summary": "Need someone to fix my washing machine",
    "language_detected": "english"
  },
  "missing_fields": [],
  "ai_message": "Sorry, we don't offer washing machine repair yet. We currently support: AC repair, plumbing, electrician, cleaning, tutoring, beauty, painting, carpentry, pest control, and moving services.",
  "agent_trace": [
    {"step": "extracting_intent", "message": "Reading your request...", "timestamp": "..."},
    {"step": "service_not_available", "message": "Service type 'other' is not supported", "timestamp": "..."}
  ]
}
```

### New `/api/v1/search` — Schema

**Request:**
```json
{
  "request_id": "req_a1b2c3",
  "service_type": "ac_technician",
  "location_text": "DHA Lahore",
  "user_lat": 31.4697,
  "user_lng": 74.4066,
  "urgency": "today"
}
```

**Response:**
```json
{
  "request_id": "req_a1b2c3",
  "providers": [
    {
      "id": "prov_lhr_ac_007",
      "name": "Bilal AC Works",
      "phone_number": "+923266142848",
      "rating": 4.8,
      "distance_km": 1.2,
      "eta_minutes": 18,
      "base_price": 600,
      "available": true,
      "rank_score": 0.91,
      "explanation": "Bilal is the closest available technician with an excellent rating in DHA."
    }
  ],
  "total_found": 12,
  "top_3_reasoning": "These 3 providers were selected based on proximity, rating, and availability in DHA Lahore.",
  "agent_trace": [
    {"step": "querying_providers", "message": "Searching for AC technicians near DHA Lahore...", "timestamp": "..."},
    {"step": "calculating_distances", "message": "Computing distances for 12 available providers...", "timestamp": "..."},
    {"step": "ranking_complete", "message": "Top 3 selected — closest: Bilal AC Works (1.2 km)", "timestamp": "..."}
  ]
}
```

### New `/api/v1/book` — Schema

**Request:**
```json
{
  "request_id": "req_a1b2c3",
  "provider_id": "prov_lhr_ac_007",
  "user_phone_number": "+923001234567",
  "time_slot": "2026-05-20T14:00:00"
}
```

**Response:**
```json
{
  "booking_id": "bkg_x1y2z3",
  "tracking_id": "TRK-2026-001",
  "status": "confirmed",
  "provider_name": "Bilal AC Works",
  "provider_phone": "+923266142848",
  "eta_minutes": 18,
  "confirmation_text": "Booking confirmed! Bilal will arrive in ~18 mins.",
  "simulated": true,
  "agent_trace": [
    {"step": "creating_booking", "message": "Reserving slot with Bilal AC Works...", "timestamp": "..."},
    {"step": "booking_confirmed", "message": "Booking TRK-2026-001 confirmed — ETA 18 mins", "timestamp": "..."}
  ]
}
```

---

## Files to Change

### Backend Code
| File | Action |
|------|--------|
| `app/schemas/parse_request.py` | **Rewrite** — new ParseInput/ParseResponse with `intent`, `missing_fields`, `ai_message`, `agent_trace` |
| `app/schemas/providers.py` | **Update** — SearchRequest adds `location_text`, response adds `top_3_reasoning` + `agent_trace` |
| `app/schemas/bookings.py` | **Update** — BookRequest adds `user_phone_number`, response adds `tracking_id` + `agent_trace` |
| `app/schemas/traces.py` | **Rewrite** — `TraceStep` model for embedded trace entries |
| `app/schemas/__init__.py` | Update imports |
| `app/services/firestore_client.py` | Add `append_trace()` method, remove "NO trace" comment |

### Docs
| File | Action |
|------|--------|
| `docs/api_design.md` | **Full rewrite** — new endpoint names, new schemas, delete `/demo/run` |
| `docs/architecture.md` | Update diagram, add trace storage, remove demo refs |
| `docs/tasks.md` | **Full rewrite** — new task list matching new endpoints |
| `docs/decisions.md` | Update Decision 11 (traces now stored), add Decision 14 (conversational flow) |
| `docs/prompts.md` | Update Prompt 1 to also generate `ai_message` and handle missing fields |

---

## What Frontend Team Can Build Right Now

With the `/api/v1/parse` schema above, the frontend can immediately build:

1. **Home Screen** → text input → POST `/api/v1/parse`
2. **"Thinking" animation** → read `agent_trace` array, animate steps sequentially
3. **Complete case** → show editable form with extracted intent fields
4. **Incomplete case** → show `ai_message` as chat bubble, prompt user for missing field
5. **Service not available** → show `ai_message` as error with list of supported services

> [!IMPORTANT]
> The `user_id` is NOT in the request body anymore — it comes from the Firebase JWT via the `get_current_user` dependency. The frontend just needs to send the auth header.
