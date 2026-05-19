# Step 1: Backend Skeleton — Task Tracker

## Files Created
- [x] `.env.example` — placeholders only
- [x] `.env` — GCP values filled, MAPS_API_KEY from env
- [x] `requirements.txt` — all deps installed globally
- [x] `app/__init__.py`
- [x] `app/config.py` — pydantic-settings, hard exit on missing keys
- [x] `app/main.py` — FastAPI + lifespan + CORS + /health
- [x] `app/auth/__init__.py`
- [x] `app/auth/firebase_auth.py` — real Firebase JWT verification
- [x] `app/schemas/__init__.py`
- [x] `app/schemas/common.py` — HealthResponse, ErrorResponse
- [x] `app/schemas/parse_request.py` — ParseRequestInput, ParseRequestResponse
- [x] `app/schemas/providers.py` — ProviderSearchRequest, Provider, ProviderSearchResponse
- [x] `app/schemas/bookings.py` — BookingCreateRequest, BookingCreateResponse, BookingStatusResponse
- [x] `app/schemas/followups.py` — FollowupRequest, FollowupResponse
- [x] `app/schemas/history.py` — HistoryRequestItem, HistoryBookingItem
- [x] `app/services/__init__.py`
- [x] `app/services/gemini_client.py` — google-genai SDK with Vertex AI backend
- [x] `app/services/firestore_client.py` — CRUD helpers, NO traces
- [x] `app/services/maps_client.py` — Distance Matrix API wrapper
- [x] `app/api/__init__.py`

## Verification
- [x] `pip install -r requirements.txt` — all installed
- [x] `uvicorn app.main:app` — starts clean, no deprecation warnings
- [x] `GET /health` → `{"status": "ok", "services": {"firestore": true, "gemini": true, "maps": true}}`
- [x] No real keys in `.env.example`

## Notes
- Used `google-genai` SDK (not deprecated `vertexai.generative_models`) to avoid deprecation warning
- Model set to `gemini-2.0-flash` (latest flash model available via google-genai)
- MAPS_API_KEY picked up from system environment variable
- Service account file verified at `backend/aiseekho-service-orchestrator-38e03530d861.json`
