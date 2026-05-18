# API Design — AISeekho Challenge 2

Base URL: `https://<your-backend>/api/v1`
Auth: Firebase JWT in `Authorization: Bearer <token>` header

---

## Endpoints

### POST /parse-request
Calls Gemini. Returns structured intent from raw user text.

**Request:**
```json
{
  "user_id": "uid_abc",
  "raw_text": "mujhe aaj AC theek karwana hai, main DHA Lahore mein hoon",
  "language_hint": "roman_urdu"
}
```

**Response:**
```json
{
  "request_id": "req_001",
  "service_type": "ac_technician",
  "location_text": "DHA Lahore",
  "urgency": "today",
  "issue_summary": "AC repair needed urgently",
  "parsed_ok": true
}
```

---

### POST /providers/search
Deterministic. Filters + ranks providers. Calls Maps Distance Matrix.

**Request:**
```json
{
  "request_id": "req_001",
  "service_type": "ac_technician",
  "user_lat": 31.4697,
  "user_lng": 74.4066,
  "urgency": "today"
}
```

**Response:**
```json
{
  "providers": [
    {
      "id": "prov_12",
      "name": "Usman AC Services",
      "rating": 4.7,
      "distance_km": 1.2,
      "eta_minutes": 18,
      "base_price": 500,
      "available": true,
      "rank_score": 0.91,
      "explanation": "Closest available technician with highest rating in your area."
    }
  ],
  "total_found": 5
}
```

---

### POST /bookings/create
Creates simulated booking record in Firestore.

**Request:**
```json
{
  "request_id": "req_001",
  "provider_id": "prov_12",
  "user_id": "uid_abc",
  "time_slot": "2025-01-15T14:00:00"
}
```

**Response:**
```json
{
  "booking_id": "bkg_777",
  "status": "confirmed",
  "provider_name": "Usman AC Services",
  "eta_minutes": 18,
  "confirmation_text": "Booking confirmed! Usman will arrive in ~18 mins.",
  "simulated": true
}
```

---

### GET /bookings/{booking_id}
Fetch booking state.

**Response:**
```json
{
  "booking_id": "bkg_777",
  "status": "en_route",
  "provider_name": "Usman AC Services",
  "eta_minutes": 12,
  "last_updated": "2025-01-15T14:05:00"
}
```

---

### GET /providers/nearby
Quick map pin data. No ranking logic.

**Query params:** `lat`, `lng`, `service_type`, `radius_km`

**Response:**
```json
{
  "providers": [
    { "id": "prov_12", "name": "Usman AC Services", "lat": 31.471, "lng": 74.408 }
  ]
}
```

---

### GET /traces/{request_id}
Returns step-by-step log of workflow for a request. Used for demo evidence.

**Response:**
```json
{
  "request_id": "req_001",
  "steps": [
    { "step": "parse_request", "input": "...", "output": "...", "timestamp": "..." },
    { "step": "provider_search", "input": "...", "output": "...", "timestamp": "..." },
    { "step": "booking_created", "input": "...", "output": "...", "timestamp": "..." }
  ]
}
```

---

### POST /followups/reminder
Generates AI reminder/follow-up text. Calls Gemini with short prompt.

**Request:**
```json
{
  "booking_id": "bkg_777",
  "trigger": "pre_arrival"
}
```

**Response:**
```json
{
  "message": "Your technician Usman is 5 mins away. Please have access to the AC unit ready.",
  "send_at": "2025-01-15T14:10:00"
}
```

---

### POST /demo/run
Single-button full pipeline trigger. For hackathon demo only.

**Request:**
```json
{
  "raw_text": "Need AC repair in DHA Lahore today",
  "user_lat": 31.4697,
  "user_lng": 74.4066
}
```

**Response:** Full pipeline result: parse → providers → booking → follow-up in one call.

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
