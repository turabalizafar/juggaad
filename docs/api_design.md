# API Design — AISeekho Challenge 2

Base URL: `https://<your-backend>/api/v1`
Auth: Firebase JWT in `Authorization: Bearer <token>` header (user_id extracted from token)

---

## Endpoints

### POST /parse
Calls Gemini Prompt 1 for JSON intent extraction. Missing fields and ai_message are generated deterministically in Python — NOT by Gemini.

**Request:**
```json
{
  "raw_text": "mujhe aaj AC theek karwana hai, main DHA Lahore mein hoon",
  "language_hint": "roman_urdu"
}
```

**Response (complete):**
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
    {"step": "extracting_intent", "message": "Reading your request...", "timestamp": "..."},
    {"step": "intent_extracted", "message": "Service: AC Technician, Location: DHA Lahore, Time: Today", "timestamp": "..."}
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
  "ai_message": "Sorry, we don't offer this service yet. We support: AC repair, plumbing, electrician, cleaning, tutoring, beauty, painting, carpentry, pest control, and moving services.",
  "agent_trace": [
    {"step": "extracting_intent", "message": "Reading your request...", "timestamp": "..."},
    {"step": "service_not_available", "message": "Service type 'other' is not supported", "timestamp": "..."}
  ]
}
```

---

### POST /search
Deterministic. Filters + ranks providers. Calls Maps Distance Matrix. Uses Gemini Prompt 2 for per-provider explanation. Returns top 3.

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
      "lat": 31.4812,
      "lng": 74.3978,
      "explanation": "Bilal is the closest available technician with an excellent rating in DHA."
    }
  ],
  "total_found": 12,
  "top_3_reasoning": "These 3 providers were selected based on proximity, rating, and availability in DHA Lahore.",
  "ai_header_text": "3 Great Matches Near You",
  "agent_trace": [
    {"step": "querying_providers", "message": "Searching for AC technicians near DHA Lahore...", "timestamp": "..."},
    {"step": "calculating_distances", "message": "Computing distances for 12 available providers...", "timestamp": "..."},
    {"step": "ranking_complete", "message": "Top 3 selected — closest: Bilal AC Works (1.2 km)", "timestamp": "..."}
  ]
}
```

---

### POST /book
Creates simulated booking record in Firestore.

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

### GET /booking/{booking_id}
Fetch booking state for tracking screen.

**Response:**
```json
{
  "booking_id": "bkg_x1y2z3",
  "tracking_id": "TRK-2026-001",
  "status": "en_route",
  "provider_name": "Bilal AC Works",
  "provider_phone": "+923266142848",
  "eta_minutes": 12,
  "last_updated": "2026-05-20T14:05:00"
}
```

---

### POST /followup
Generates AI reminder/follow-up text. Calls Gemini with Prompt 3.

**Request:**
```json
{
  "booking_id": "bkg_x1y2z3",
  "trigger": "pre_arrival"
}
```

**Response:**
```json
{
  "message": "Your technician Bilal is 5 mins away. Please have access to the AC unit ready.",
  "send_at": "2026-05-20T14:10:00"
}
```

---

### GET /history/requests
Returns past service requests for the authenticated user.

**Response:**
```json
{
  "requests": [
    {
      "request_id": "req_a1b2c3",
      "service_type": "ac_technician",
      "location_text": "DHA Lahore",
      "urgency": "today",
      "issue_summary": "AC repair needed today",
      "created_at": "2026-05-20T13:00:00",
      "status": "completed"
    }
  ]
}
```

---

### GET /history/bookings
Returns past bookings. Includes provider phone for "Call Again".

**Response:**
```json
{
  "bookings": [
    {
      "booking_id": "bkg_x1y2z3",
      "request_id": "req_a1b2c3",
      "provider_id": "prov_lhr_ac_007",
      "provider_name": "Bilal AC Works",
      "provider_phone": "+923266142848",
      "service_type": "ac_technician",
      "status": "completed",
      "time_slot": "2026-05-20T14:00:00",
      "created_at": "2026-05-20T13:30:00"
    }
  ]
}
```

---

## Ranking Formula (Deterministic)

```
rank_score = (0.4 × availability_score)
           + (0.3 × normalized_distance_score)
           + (0.2 × rating_score)
           + (0.1 × response_time_score)
```

All scores normalized 0–1. Higher = better. Backend calculates, not AI.

---

## Error Shape

```json
{
  "error": "provider_not_found",
  "message": "No AC technicians available in your area.",
  "code": 404
}
```
