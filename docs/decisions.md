# Decisions — AISeekho Challenge 2

Architecture decisions with rationale. Update this file when something changes.

---

## Decision 1: Multiple Service Categories
**Chosen:** Support 10 categories in mock data (ac_technician, plumber, electrician, cleaner, tutor, beautician, painter, carpenter, pest_control, shifting_service)  
**Why:** Demonstrates system flexibility; if service not in dataset → returns clear `service_not_available` response  
**Trade-off:** More mock data to seed, but shows the system is not hardcoded to one lane  

---

## Decision 2: Firestore over PostgreSQL
**Chosen:** Firestore  
**Why:** Firebase Auth already in stack, real-time streaming for Flutter (StreamBuilder), no schema migrations, fast to seed, flexible for hackathon iteration  
**Trade-off:** No joins, less familiar for SQL-trained devs  

---

## Decision 3: Gemini 2.0 Flash (via google-genai SDK)
**Chosen:** gemini-2.0-flash via google-genai SDK with vertexai=True  
**Why:** Cheaper, faster, no deprecation warnings (unlike old vertexai.generative_models), enough for structured JSON extraction and short NL generation  
**Trade-off:** Less capable on complex reasoning — acceptable since we use it for simple tasks only  

---

## Decision 4: Mock Provider Data (not real scraping)
**Chosen:** Seeded JSON with ~300 fake providers across 10 categories and 18 cities (3 geographic clusters)  
**Why:** No real API exists for informal service providers in Pakistan; building one is out of scope; mock is standard for hackathons  
**Trade-off:** Not real-world validated  
**Mitigations:** Realistic coordinates per city, realistic names and ratings, ~20% unavailable, all share demo phone number  

---

## Decision 5: REST over SOAP or GraphQL
**Chosen:** REST/JSON  
**Why:** Fastest to build, mobile-friendly, standard, Dio + FastAPI native support  
**Ruled out:** SOAP (outdated, verbose); GraphQL (overkill for 3-day build)  

---

## Decision 6: Ranking is Deterministic, Not AI
**Chosen:** Backend math formula for ranking  
**Why:** Deterministic = debuggable, reproducible, no hallucination risk, no token cost  
**Formula:** `0.4 × availability + 0.3 × distance + 0.2 × rating + 0.1 × response_time`  
**AI role:** Explain the winner in natural language only, after ranking is done  

---

## Decision 7: Cloud Run for Backend Hosting
**Chosen:** Cloud Run (containerized FastAPI)  
**Why:** Google ecosystem (Firestore, Maps, Vertex AI all same GCP project), free tier generous, HTTPS auto  
**Alternative:** Render if GCP setup takes too long on demo day  

---

## Decision 8: Riverpod for Flutter State
**Chosen:** Riverpod  
**Why:** Cleaner than Provider, easier than Bloc for small apps, good async support for API calls  
**Trade-off:** Learning curve if team hasn't used it — use `flutter_riverpod` + `AsyncNotifier`  

---

## Decision 9: No Real Push Notifications
**Chosen:** Simulated follow-up only (in-app message)  
**Why:** FCM integration is extra complexity, demo doesn't need real push  
**Scope:** Show reminder text in Flutter UI after booking confirmed  

---

## Decision 10: Provider Phone Numbers
**Chosen:** Include `phone_number` for every provider — all use `+923266142848`  
**Why:** Enables "Call Again" in history, shows provider contact in booking confirmation, live demo routing  
**Trade-off:** Single number for all providers — acceptable for demo  

---

## Decision 11: Traces Stored IN Firestore (reversed)
**Chosen:** Store agent trace logs in Firestore inside `service_requests/{request_id}.agent_trace[]`  
**Previous:** "Do not store traces in Firestore" — reversed to support real-time Flutter streaming  
**Why:** Firestore is a real-time database. Flutter can use StreamBuilder to listen to the document and animate trace steps as they appear — makes the "agentic thinking" UI feel alive  
**Mechanism:** Backend uses `firestore.ArrayUnion()` to append trace entries incrementally  

---

## Decision 12: Real Firebase Auth (not guest/test user)
**Chosen:** Real Firebase Auth with JWT verification on every request  
**Why:** Demonstrates production-grade auth flow, required by challenge  
**Trade-off:** Slightly more setup, but already implemented  

---

## Decision 13: No Demo Button
**Chosen:** Manual flow only — no `/demo/run` endpoint, no "Run Demo" button, no "Continue as Guest"  
**Why:** Shows genuine user interaction, not scripted automation  
**Trade-off:** Demo requires manual walkthrough (more impressive to judges)  

---

## Decision 14: Conversational Multi-Step Flow
**Chosen:** Separate endpoints for each step: `/parse` → `/search` → `/book`  
**Why:** Enables step-by-step conversational UI where user confirms/edits data between steps  
**Rejected:** Single "Master Orchestrator" endpoint returning massive JSON payload  
**Trade-off:** More HTTP calls, but much better UX and matches the "agentic thinking" requirement  

---

## Decision 15: ai_message is Deterministic (NOT AI)
**Chosen:** Generate ai_message and missing_fields with hardcoded Python strings, NOT Gemini  
**Why:** "One job per prompt" rule — mixing JSON extraction with creative writing in Prompt 1 risks breaking JSON parsing. Also saves Vertex AI tokens.  
**Implementation:** Python if/else in endpoint handler with hardcoded Urdu/English messages  

---

## Open Questions (not yet decided)

1. **Maps Nearby Search:** Use real Google Places for providers or stick to mock coords?  
   → Recommendation: mock coords + Maps SDK for visual only  
2. **Urdu input:** Accept Roman Urdu via text input or add voice (Speech-to-Text)?  
   → Recommendation: text input only, voice as stretch  
