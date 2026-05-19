# Task Tracker

## Step 1: Backend Skeleton ✅
- [x] `.env.example`, `.env`, `requirements.txt`
- [x] `app/config.py` — pydantic-settings, hard exit on missing keys
- [x] `app/main.py` — FastAPI + lifespan + CORS + /health
- [x] `app/auth/firebase_auth.py` — real Firebase JWT verification
- [x] `app/schemas/` — all 6 schema files matching api_design.md
- [x] `app/services/gemini_client.py` — google-genai SDK, Vertex AI
- [x] `app/services/firestore_client.py` — CRUD helpers, no traces
- [x] `app/services/maps_client.py` — Distance Matrix API
- [x] Health check: all 3 services green

## Step 1.5: Phone Number Schema Update ✅
- [x] `schemas/providers.py` — added `phone_number` to Provider
- [x] `schemas/bookings.py` — added `user_phone_number` + `provider_phone`
- [x] `schemas/history.py` — added `provider_phone` for Call Again
- [x] Updated docs: architecture, api_design, tasks, decisions, context, ui_and_antigravity

## Step 2: Mock Provider Dataset ✅
- [x] `scripts/generate_mock_data.py` — generates 300 providers
- [x] `data/mock_providers.json` — 300 providers, 10 categories, 18 cities, 3 clusters
- [x] `scripts/seed_db.py` — clears + seeds Firestore
- [x] Firestore API enabled + database created (Native mode)
- [x] Seeded 300 providers successfully
- [x] Verified: all categories present, phone = +923266142848, correct clusters

## Next: Step 3
- [ ] `/parse-request` endpoint using Prompt 1 from docs/prompts.md
- [ ] Call Gemini, validate JSON with Pydantic
- [ ] Store service_request in Firestore
