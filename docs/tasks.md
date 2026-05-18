# Tasks — AISeekho Challenge 2

Build order: backend flow first, UI second. Mock data ready before any endpoint tested.

---

## Day 1: Foundation

### Task 1.1 — Repo + Structure
- [ ] Create GitHub repo
- [ ] Add `docs/`, `backend/`, `mobile/` folders
- [ ] Add `.env.example`, `README.md`
- [ ] Add all teammates as collaborators
- [ ] Commit this `docs/` folder

### Task 1.2 — Mock Provider Data
- [ ] Create `backend/data/providers.json`
- [ ] Seed 30 AC technician providers (Lahore-DHA area)
- [ ] Fields: id, name, rating, lat, lng, availability_status, base_price, response_time_estimate
- [ ] Include ~5 unavailable providers (for realism in ranking)
- [ ] Seed to Firestore `providers` collection

### Task 1.3 — FastAPI Skeleton
- [ ] Setup FastAPI app with CORS
- [ ] Setup Firebase Admin SDK (for Firestore + Auth verify)
- [ ] Gemini client init (google-generativeai or vertexai SDK)
- [ ] Health check: `GET /health` → `{"status": "ok"}`
- [ ] Pydantic schemas for all request/response shapes

### Task 1.4 — Parse Request Endpoint
- [ ] `POST /api/v1/parse-request`
- [ ] Call Gemini with Prompt 1
- [ ] Parse JSON response, validate with Pydantic
- [ ] Save `service_request` to Firestore
- [ ] Log trace step: `parse_request`
- [ ] Return structured intent JSON

---

## Day 2: Core Flow

### Task 2.1 — Provider Search + Ranking
- [ ] `POST /api/v1/providers/search`
- [ ] Filter providers by `service_type` from mock data
- [ ] Call Maps Distance Matrix API for top 10 candidates
- [ ] Apply ranking formula (availability × distance × rating × response_time)
- [ ] Call Gemini with Prompt 2 for top result explanation
- [ ] Log trace step: `provider_search`
- [ ] Return ranked list with explanation

### Task 2.2 — Booking Simulation
- [ ] `POST /api/v1/bookings/create`
- [ ] Create booking record in Firestore
- [ ] Set status: `confirmed`
- [ ] Return confirmation text + ETA
- [ ] `GET /api/v1/bookings/{booking_id}`
- [ ] Log trace step: `booking_created`

### Task 2.3 — Follow-up Service
- [ ] `POST /api/v1/followups/reminder`
- [ ] Call Gemini with Prompt 3 based on trigger type
- [ ] Return reminder message
- [ ] Log trace step: `followup_generated`

### Task 2.4 — Trace Endpoint
- [ ] `GET /api/v1/traces/{request_id}`
- [ ] Read all trace steps from Firestore for given request_id
- [ ] Return ordered step log

### Task 2.5 — Demo Endpoint
- [ ] `POST /api/v1/demo/run`
- [ ] Chain: parse → search → book → followup in one call
- [ ] Return full pipeline result
- [ ] Used for demo button in Flutter

---

## Day 3: Flutter + Polish

### Task 3.1 — Flutter Setup
- [ ] Flutter project init with Riverpod + Dio + Firebase
- [ ] Configure google_maps_flutter
- [ ] Setup Dio base URL + auth interceptor (attach Firebase JWT)

### Task 3.2 — Core Screens (priority order)
- [ ] Screen 1: Login/Welcome
- [ ] Screen 2: Home (input box + demo button)
- [ ] Screen 3: Parsed Request Preview
- [ ] Screen 4: Provider Ranking List
- [ ] Screen 5: Map view with provider pins
- [ ] Screen 6: Booking Confirmation
- [ ] Screen 7: Tracking / Follow-up

### Task 3.3 — Connect Frontend to Backend
- [ ] Home → POST /parse-request → show parsed preview
- [ ] Parsed preview → POST /providers/search → show list
- [ ] Provider selected → POST /bookings/create → show confirmation
- [ ] Confirmation → POST /followups/reminder → show reminder

### Task 3.4 — Demo Polish
- [ ] "Run Demo" button on Home screen → POST /demo/run → full flow auto-play
- [ ] Loading states on all network calls
- [ ] Map shows provider pins
- [ ] Error states for no providers found

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
- Any category beyond AC technician for demo
