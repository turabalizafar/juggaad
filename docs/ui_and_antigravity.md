# UI Screen Map — AISeekho Challenge 2 (Google Stitch)

7 screens. Each described for Stitch layout generation.

---

## Screen 1: Login / Welcome

**Purpose:** Entry point. Firebase Auth.  
**Layout:** Centered card, logo top, tagline, action buttons bottom  
**Components:**
- App logo + name "Juggaad"
- Tagline: "Find trusted services near you"
- "Sign in with Google" button (primary)
- "Continue as Guest" text link (for demo)

**User action:** Tap Google sign-in → go to Home  
**Data needed:** Firebase Auth response (UID, display name)

---

## Screen 2: Home (Request Input)

**Purpose:** Main entry. User types service request.  
**Layout:** Clean, large input area center. Bottom nav bar.  
**Components:**
- Greeting: "What do you need help with today?"
- Large multi-line text field (placeholder: "e.g. Mujhe AC theek karwana hai DHA Lahore mein")
- "Find Providers" button (primary, full width)
- "Run Demo" button (secondary) → triggers POST /demo/run
- Recent requests list (if history exists)

**User action:** Type request → tap "Find Providers" → POST /parse-request  
**Data needed:** User location (lat/lng from typed through google maps api)

---

## Screen 3: Parsed Request Preview

**Purpose:** Show user what AI understood. Builds trust.  
**Layout:** Card-based summary, edit option, proceed CTA  
**Components:**
- Header: "Here's what I understood"
- Service type chip (e.g., 🔧 AC Technician)
- Location line (e.g., 📍 DHA Lahore)
- Urgency badge (e.g., ⚡ Today)
- Issue summary text
- "Edit" icon (tap to go back)
- "Find Providers" button → POST /providers/search

**User action:** Confirm or go back to edit  
**Data needed:** Response from /parse-request

---

## Screen 4: Provider Ranking List

**Purpose:** Core value screen. Ranked providers with explanation.  
**Layout:** List of provider cards + Map toggle button top right  
**Components:**
- "5 providers found near you" header
- Sort tabs: [Best Match] [Nearest] [Highest Rated]
- Provider card (per result):
  - Provider name + avatar initial
  - Rating stars + number
  - Distance (km) + ETA (mins)
  - Price badge
  - "Available" / "Busy" chip
  - Rank score bar (visual)
- AI explanation text under top result (italicized, subtle)
- "Book" button on each card → go to Booking Confirmation
- Map icon (top right) → go to Screen 5

**User action:** Tap "Book" on any provider  
**Data needed:** Response from /providers/search

---


## Screen 5: Booking Confirmation

**Purpose:** Show confirmed booking. Simulate real state.  
**Layout:** Success illustration top, booking details card, CTA  
**Components:**
- Green checkmark / success animation
- "Booking Confirmed!" heading
- Provider name, rating, ETA countdown (simulated)
- Booking ID badge
- Estimated arrival time
- "Track Provider" button → Screen 6
- "Back to Home" text link

**User action:** Tap "Track Provider" → Screen 6
**Data needed:** Response from /bookings/create

---

## Screen 6: Tracking / Follow-up

**Purpose:** Simulate real-time tracking. Show follow-up message.  
**Layout:** Status timeline top, map mini-view center, message bottom  
**Components:**
- Status steps: [Confirmed] → [En Route] → [Arrived] → [Complete]
  (animated, simulated progression)
- Mini map (provider pin moving toward user — optional, can be static)
- ETA countdown timer (simulated)
- Follow-up message card (from /followups/reminder)
  - e.g., "Your technician is 5 mins away. Please keep AC accessible."
- "Rate Provider" button (after completion state)

**User action:** Watch simulation, receive message  
**Data needed:** GET /bookings/{booking_id}, POST /followups/reminder

---

# Master Antigravity Prompt

Paste this into Antigravity to begin implementation.

---

```
You are building "Juggaad" — an AI-powered service orchestration mobile app for the AISeekho Challenge 2 hackathon.

SOURCE OF TRUTH: Read docs/ folder files first before writing any code.
- docs/architecture.md — system design and layer roles
- docs/api_design.md — all endpoint contracts with exact JSON shapes
- docs/prompts.md — Gemini prompts (use exactly as written)
- docs/tasks.md — build order (follow this order)
- docs/decisions.md — why we chose each tech

STACK: Flutter (mobile) + FastAPI (backend) + Firestore + Google Maps + Gemini 1.5 Flash

HARD RULES:
1. Do NOT write monolithic code. One module per task.
2. Do NOT use AI for ranking math, distance, or database logic.
3. Use Gemini ONLY for: intent extraction, explanation generation, follow-up text.
4. Follow the exact JSON schemas in docs/api_design.md.
5. Log every pipeline step to Firestore traces collection.
6. Keep Gemini prompts small — max 200 tokens input per call.
7. Do NOT overbuild. MVP only. AC Technician demo lane only.

---

TASK 1 — Backend skeleton (do this first):
Create FastAPI project in backend/ folder.
Files needed:
- backend/app/main.py (FastAPI app, CORS, health check)
- backend/app/schemas/ (Pydantic models for all endpoints)
- backend/app/services/gemini_client.py (Gemini API wrapper)
- backend/app/services/firestore_client.py (Firestore wrapper)
- backend/requirements.txt
Do not build any endpoint logic yet. Just the skeleton and clients.
Confirm when done.

---

TASK 2 — Mock provider data:
Create backend/data/providers.json with 30 AC technician providers.
All in Lahore DHA area (lat ~31.45–31.50, lng ~74.35–74.42).
Fields per provider: id, name, rating (3.5–5.0), lat, lng, availability_status (true/false, ~5 false), base_price (400–900), response_time_minutes (10–45).
Also create a script backend/scripts/seed_firestore.py that reads this JSON and writes to Firestore providers collection.
Confirm when done.

---

TASK 3 — Parse request endpoint:
Build POST /api/v1/parse-request.
Use exact prompt from docs/prompts.md Prompt 1.
Call Gemini 1.5 Flash. Parse response as JSON. Validate with Pydantic.
Save service_request to Firestore. Log trace step "parse_request".
Return structured intent JSON exactly matching docs/api_design.md schema.
Confirm when done. Show me a test curl command.

---

TASK 4 — Provider search + ranking:
Build POST /api/v1/providers/search.
Filter providers from Firestore by service_type.
Call Google Maps Distance Matrix API for top 10 nearest candidates.
Apply ranking formula: 0.4×availability + 0.3×distance_score + 0.2×rating_score + 0.1×response_time_score (all normalized 0–1).
Call Gemini with Prompt 2 (docs/prompts.md) for top result explanation.
Log trace step "provider_search".
Return ranked list matching docs/api_design.md schema.
Confirm when done.

---

TASK 5 — Booking + follow-up + demo endpoint:
Build POST /api/v1/bookings/create.
Build GET /api/v1/bookings/{booking_id}.
Build POST /api/v1/followups/reminder (use Prompt 3 from docs/prompts.md).
Build GET /api/v1/traces/{request_id}.
Build POST /api/v1/demo/run (chain: parse → search → book → followup).
Log trace steps for each.
Confirm when done.

---

TASK 6 — Flutter screens (only after Tasks 1–5 confirmed):
Create Flutter project in mobile/ folder.
Dependencies: flutter_riverpod, dio, google_maps_flutter, firebase_auth, firebase_core.
Build these screens IN ORDER:
1. HomeScreen — text input + "Find Providers" + "Run Demo" buttons
2. ParsedRequestScreen — show intent JSON as readable card
3. ProviderListScreen — ranked provider cards with explanation text
4. MapScreen — Google Map with provider pins
5. BookingConfirmScreen — success state with ETA
6. TrackingScreen — status timeline + follow-up message

Wire each screen to backend via Dio. Use Riverpod AsyncNotifier per screen.
Match the UI layout from docs/ui_screens.md (the screen map).
Confirm when done.

---

TASK 7 — Polish and evidence:
Add loading states to all screens.
Add error states (no providers found, network error).
Verify demo/run flow works end-to-end.
Export one sample trace from Firestore and save to docs/traces/api_logs/.
List any incomplete items.
```
