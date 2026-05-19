# AI Orchestrator - Backend & UI Integration Contract

## 1. The Real-Time "Thinking" Stream (Firestore)
To show the judges that the AI is "thinking" and executing steps, the UI must NOT wait for a massive HTTP response. Instead, it must listen to a Firestore document using a `StreamBuilder`.
* **Collection:** `service_requests`
* **Document ID:** Returned by the `/parse` endpoint as `request_id`.
* **Field to watch:** `agent_trace` (Array of strings). 
* **UI Action:** As the backend appends strings to this array (e.g., "Extracting intent...", "Querying DB...", "Calculating distances..."), the Flutter UI should animate them appearing on the screen sequentially.

## 2. REST API Endpoints & JSON Schemas

### Step A: Parse Request (`POST /api/v1/parse`)
Sends the user's natural language string to extract intent.

**Request:**
```json
{
  "query": "Mujhe kal AC theek karwana hai DHA mein",
  "user_phone_number": "+923266142848"
}
Response (If Missing Info):

JSON
{
  "status": "incomplete",
  "request_id": "req_12345",
  "intent": {
    "service_type": "ac_technician",
    "location_text": "DHA",
    "urgency": null
  },
  "missing_fields": ["urgency"],
  "ai_message": "Barahe meherbani apna time bataen — aapko kab service chahiye?"
}
UI Action: Show ai_message in a chat bubble, let the user reply to provide the missing time.

Response (If Complete):

JSON
{
  "status": "complete",
  "request_id": "req_12345",
  "intent": {
    "service_type": "ac_technician",
    "location_text": "DHA",
    "urgency": "tomorrow"
  },
  "ai_message": "Got it! Please confirm the details below before I search."
}
UI Action: Show an editable form with the extracted details so the user can verify.

Step B: Search & Reason (POST /api/v1/search)
Triggered when the user confirms the form.

Request:

JSON
{
  "request_id": "req_12345",
  "confirmed_intent": {
    "service_type": "ac_technician",
    "location_text": "DHA",
    "urgency": "tomorrow"
  }
}
Response:

JSON
{
  "status": "success",
  "reasoning_message": "I found 3 highly-rated AC technicians near DHA. Usman is the closest and has a 5-star rating.",
  "top_providers": [
    {
      "provider_id": "prov_lh_ac_001",
      "name": "Usman AC Repair",
      "rating": 4.9,
      "distance_km": 2.3,
      "phone_number": "+923266142848"
    }
    // ... 2 more providers
  ]
}
UI Action: Display the reasoning_message prominently, and show the top providers in selectable cards.

Step C: Book Service (POST /api/v1/book)
Triggered when the user taps "Book" on a provider card.

Request:

JSON
{
  "request_id": "req_12345",
  "provider_id": "prov_lh_ac_001"
}
Response:

JSON
{
  "status": "success",
  "tracking_id": "TRK-998877",
  "eta_minutes": 15,
  "message": "Booking confirmed! Usman is on the way."
}
UI Action: Show the final success screen with the ETA and Tracking ID.