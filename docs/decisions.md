# Decisions — AISeekho Challenge 2

Architecture decisions with rationale. Update this file when something changes.

---

## Decision 1: Hero Category = AC Technician
**Chosen:** AC Technician only for demo  
**Why:** Fast to mock, universally relatable, clear problem (urgent service need), good for summer demo context in Pakistan  
**Trade-off:** Looks narrow, but deep > wide for hackathon judges  

---

## Decision 2: Firestore over PostgreSQL
**Chosen:** Firestore  
**Why:** Firebase Auth already in stack, no schema migrations, fast to seed, flexible for hackathon iteration, good Flutter SDK  
**Trade-off:** No joins, less familiar for SQL-trained devs  
**Fallback:** PostgreSQL if team strongly prefers relational  

---

## Decision 3: Gemini 1.5 Flash (not Pro)
**Chosen:** gemini-1.5-flash  
**Why:** Cheaper, faster, enough for structured JSON extraction and short NL generation  
**Trade-off:** Less capable on complex reasoning — acceptable since we use it for simple tasks only  
**Switch to Pro if:** Flash fails on Roman Urdu parsing after testing  

---

## Decision 4: Mock Provider Data (not real scraping)
**Chosen:** Seeded JSON with ~30 fake providers  
**Why:** No real API exists for informal service providers in Pakistan; building one is out of scope; mock is standard for hackathons  
**Trade-off:** Not real-world validated  
**Mitigations:** Realistic coordinates (DHA Lahore), realistic names and ratings, some unavailable  

---

## Decision 5: REST over SOAP or GraphQL
**Chosen:** REST/JSON  
**Why:** Fastest to build, mobile-friendly, standard, Dio + FastAPI native support  
**Ruled out:** SOAP (outdated, verbose, no benefit here); GraphQL (overkill for 3-day build)  

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

## Open Questions (not yet decided)

1. **Auth in demo:** Use real Firebase Auth or skip auth for speed and use hardcoded test user?  
   → Recommendation: hardcode test user for demo, real auth as stretch  
2. **Maps Nearby Search:** Use real Google Places for providers or stick to mock coords?  
   → Recommendation: mock coords + Maps SDK for visual only  
3. **Urdu input:** Accept Roman Urdu via text input or add voice (Speech-to-Text)?  
   → Recommendation: text input only, voice as stretch  
