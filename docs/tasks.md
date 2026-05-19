# Tasks — AISeekho Challenge 2

Build order: backend flow first, UI in parallel. Mock data ready before any endpoint tested.

---

## Day 1: Foundation

### Task 1.1 — Repo + Structure
- [x] Create GitHub repo
- [x] Add `docs/`, `backend/`, `mobile/` folders
- [x] Add `.env.example`, `README.md`
- [x] Commit this `docs/` folder

### Task 1.2 — Mock Provider Data
- [x] Create `backend/data/mock_providers.json`
- [x] Seed ~300 providers across 10 categories and 18 cities (3 geographic clusters)
- [x] Fields: id, name, phone_number, service_type, city, area, cluster, rating, lat, lng, availability_status, base_price, response_time_minutes
- [x] All providers use phone: +923266142848 (live demo routing)
- [x] ~20% unavailable providers (for realism in ranking)
- [x] Seed to Firestore `providers` collection (clear existing first)

### Task 1.3 — FastAPI Skeleton
- [x] Setup FastAPI app with CORS
- [x] Setup Firebase Admin SDK (for Firestore + Auth verify)
- [x] Gemini client init (google-genai SDK, Vertex AI backend)
- [x] Health check: `GET /health` → `{"status": "ok"}`
- [x] Pydantic schemas for all request/response shapes (includes phone, traces, conversational flow)

### Task 1.4 — Architecture Realignment (Step 2.5)
- [x] Delete all /demo/run and guest flow references
- [x] Add agent trace logging to Firestore (arrayUnion on service_requests)
- [x] Restructure endpoints: /parse, /search, /book
- [x] Rewrite schemas: ParseInput/ParseResponse, SearchRequest/SearchResponse, BookRequest/BookResponse
- [x] Add TraceStep shared model
- [x] Update all docs to match new architecture

---

## Day 2: Core Flow (Step 3+)

### Task 2.1 — Parse Endpoint
- [ ] `POST /api/v1/parse`
- [ ] Call Gemini with Prompt 1 (JSON extraction only)
- [ ] Detect missing_fields deterministically in Python
- [ ] Generate ai_message with hardcoded strings (NOT Gemini)
- [ ] Create service_request document in Firestore with agent_trace[]
- [ ] Append trace steps via arrayUnion for Flutter streaming
- [ ] Return ParseResponse with status: complete|incomplete|service_not_available

### Task 2.2 — Search Endpoint
- [ ] `POST /api/v1/search`
- [ ] Filter providers by service_type + city from Firestore
- [ ] Call Maps Distance Matrix API for available candidates
- [ ] Apply ranking formula (availability × distance × rating × response_time)
- [ ] Call Gemini Prompt 2 for per-provider explanation
- [ ] Append trace steps to service_requests document
- [ ] Return top 3 providers with reasoning

### Task 2.3 — Book Endpoint
- [ ] `POST /api/v1/book`
- [ ] Create booking record in Firestore with tracking_id
- [ ] Set status: confirmed
- [ ] Return BookResponse with provider_phone, tracking_id, ETA
- [ ] `GET /api/v1/booking/{booking_id}` for tracking screen

### Task 2.4 — Follow-up Service
- [ ] `POST /api/v1/followup`
- [ ] Call Gemini with Prompt 3 based on trigger type
- [ ] Return reminder message

### Task 2.5 — History Endpoints
- [ ] `GET /api/v1/history/requests` — past service requests for user
- [ ] `GET /api/v1/history/bookings` — past bookings with provider_phone for "Call Again"
- [ ] Filter by user_id from auth token

---

## Day 3: Flutter + Polish (frontend teammate — parallel)

### Task 3.1 — Flutter Setup
- [ ] Flutter project init with Riverpod + Dio + Firebase
- [ ] Configure google_maps_flutter
- [ ] Setup Dio base URL + auth interceptor (attach Firebase JWT)
- [ ] Setup Firestore StreamBuilder for agent trace animation

### Task 3.2 — Core Screens (priority order)
- [ ] Screen 1: Login/Welcome (Firebase Auth)
- [ ] Screen 2: Home (input box, no demo button)
- [ ] Screen 3: Agent Thinking animation (StreamBuilder on service_requests)
- [ ] Screen 4: Parsed Preview (editable form)
- [ ] Screen 5: Provider Ranking List (top 3 with reasoning)
- [ ] Screen 6: Booking Confirmation (tracking_id, provider phone)
- [ ] Screen 7: Tracking / Map view
- [ ] Screen 8: History (Call Again)

### Task 3.3 — Connect Frontend to Backend
- [ ] Home → POST /parse → show thinking animation → show parsed preview
- [ ] Parsed preview → POST /search → show provider list with reasoning
- [ ] Provider selected → POST /book → show confirmation
- [ ] Confirmation → POST /followup → show reminder
- [ ] History → GET /history/bookings → show Call Again

### Task 3.4 — Polish
- [ ] Loading states on all network calls
- [ ] Map shows provider pins
- [ ] Error states for service_not_available, no providers found, incomplete info
- [ ] Real-time trace animation in thinking screen

### Task 3.5 — Evidence & Submission
- [ ] Screenshot each screen
- [ ] Screen record full demo flow
- [ ] Export Firestore trace records
- [ ] Fill `docs/traces/` checklist
- [ ] Update README with setup instructions
- [ ] Tag repo `v1.0-submission`

---

## Not Building (Explicit Cut)

- Real payment integration
- Real provider onboarding
- Multi-language UI (Urdu script rendering)
- Push notifications (mock only)
- Admin dashboard
- /demo/run or guest flow
- AI-generated ai_message (hardcoded strings only)
