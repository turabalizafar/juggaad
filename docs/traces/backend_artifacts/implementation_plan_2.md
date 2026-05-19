# Step 1: Backend Skeleton (Revised)

Build the FastAPI backend foundation with all clients, schemas, auth middleware, and health check. **No endpoint logic beyond health check.**

## Changes from v1
- **No traces in Firestore** — removed trace logging from Firestore client; evidence captured locally only when instructed
- **Vertex AI SDK** instead of `google-generativeai` — uses `vertexai` SDK with service account
- **Single service account JSON** serves Firebase Admin + Vertex AI
- **Missing keys = hard stop** — clear error and refuse to start, not silent fallback

## User Review Required

> [!IMPORTANT]
> I need these values before I can build. Please provide:
> 1. **GCP Project ID** (for Vertex AI init, e.g. `my-project-123`)
> 2. **GCP Region** for Vertex AI (e.g. `us-central1`)
> 3. **Service account JSON file** — do you have one already? Where is it / will it be placed?
> 4. **Google Maps API Key** — do you have one, or should I leave it as env-var-required and you'll fill it in?

## Proposed Changes

### Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI app, CORS, health check, lifespan
│   ├── config.py                  # Settings from env vars (pydantic-settings)
│   ├── auth/
│   │   ├── __init__.py
│   │   └── firebase_auth.py       # Firebase JWT verification dependency
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── parse_request.py       # ParseRequest / ParseResponse
│   │   ├── providers.py           # ProviderSearchRequest / ProviderSearchResponse
│   │   ├── bookings.py            # BookingCreate / BookingResponse / BookingStatus
│   │   ├── followups.py           # FollowupRequest / FollowupResponse
│   │   ├── history.py             # HistoryRequest / HistoryResponse
│   │   └── common.py              # ErrorResponse, HealthResponse
│   ├── services/
│   │   ├── __init__.py
│   │   ├── gemini_client.py       # Vertex AI Gemini wrapper
│   │   ├── firestore_client.py    # Firestore wrapper (NO trace logging)
│   │   └── maps_client.py         # Google Maps Distance Matrix wrapper
│   └── api/
│       └── __init__.py
├── requirements.txt
└── .env.example
```

---

### Config & Environment

#### [NEW] .env.example
Placeholder-only. Real values in `.env` (gitignored).
```
GCP_PROJECT_ID=
GCP_REGION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
GOOGLE_MAPS_API_KEY=
BACKEND_CORS_ORIGINS=http://localhost:3000
```

#### [NEW] config.py
- `pydantic-settings` `BaseSettings`, reads from `.env`
- Fields: `GCP_PROJECT_ID`, `GCP_REGION`, `GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_MAPS_API_KEY`, `BACKEND_CORS_ORIGINS`
- **On startup**: if any required field is empty/missing → raise `SystemExit` with clear message naming the missing key

---

### FastAPI App

#### [NEW] main.py
- `lifespan` context manager: init Firebase Admin SDK, Vertex AI, Firestore client
- CORS middleware from config
- `GET /health` → `{"status": "ok", "services": {"firestore": bool, "gemini": bool}}`
- If init fails for any service → health check reports it, app still starts for debugging

---

### Firebase Auth

#### [NEW] firebase_auth.py
- `get_current_user` FastAPI dependency
- Extracts `Bearer <token>` from `Authorization` header
- Calls `firebase_admin.auth.verify_id_token(token)`
- Returns `uid` on success; 401 with `{"error": "auth_required", ...}` on failure

---

### Schemas (match docs/api_design.md)

All schemas identical to v1 plan — `ParseRequestInput`, `ParseRequestResponse`, `ProviderSearchRequest`, `Provider`, `ProviderSearchResponse`, `BookingCreateRequest`, `BookingCreateResponse`, `BookingStatusResponse`, `FollowupRequest`, `FollowupResponse`, `ErrorResponse`, `HealthResponse`.

Added: `HistoryRequestItem` and `HistoryBookingItem` for the history screen.

---

### Service Clients

#### [NEW] gemini_client.py (Vertex AI)
- `GeminiClient` class
- `__init__(project_id, region)`: calls `vertexai.init(project=..., location=...)`
- `generate(system_prompt, user_prompt, max_tokens) → str`: uses `GenerativeModel("gemini-1.5-flash")` from Vertex AI SDK
- Hard error if project_id missing

#### [NEW] firestore_client.py
- `FirestoreClient` class
- `__init__()`: uses already-initialized Firebase Admin app → `firestore.client()`
- CRUD: `add_document`, `get_document`, `get_documents`, `query_collection`, `update_document`
- **No trace logging methods** — traces are NOT stored in Firestore

#### [NEW] maps_client.py
- `MapsClient` class
- `get_distance_matrix(origin, destinations) → list[dict]`: calls Distance Matrix API via `requests`
- Hard error if API key missing

---

### Dependencies

#### [NEW] requirements.txt
```
fastapi>=0.111.0
uvicorn[standard]>=0.30.0
pydantic>=2.7.0
pydantic-settings>=2.3.0
google-cloud-aiplatform>=1.56.0
firebase-admin>=6.5.0
requests>=2.32.0
python-dotenv>=1.0.0
```

---

## Verification Plan

1. `pip install -r requirements.txt` succeeds
2. With valid `.env` + service account: `uvicorn app.main:app` starts, `GET /health` returns ok
3. With missing keys: app prints clear error naming the missing key and exits
4. `.env.example` contains **no real values**
