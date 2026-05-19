# Step 1: Backend Skeleton

Build the FastAPI backend foundation with all clients, schemas, auth middleware, and health check. **No endpoint logic yet** — just the wiring.

## User Review Required

> [!IMPORTANT]
> **Firebase Service Account**: The backend needs a Firebase service account JSON file path (via `FIREBASE_SERVICE_ACCOUNT_PATH` env var) to initialize Firebase Admin SDK for both Firestore and Auth token verification. Do you have this ready, or should I add a fallback that prints a clear error and exits?

> [!IMPORTANT]
> **Gemini Model**: Docs specify `gemini-1.5-flash`. I'll use the `google-generativeai` SDK (not Vertex AI SDK) for simplicity. Confirm this is acceptable.

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
│   │   ├── providers.py           # ProviderSearchRequest / ProviderSearchResponse / Provider
│   │   ├── bookings.py            # BookingCreate / BookingResponse / BookingStatus
│   │   ├── followups.py           # FollowupRequest / FollowupResponse
│   │   ├── traces.py              # TraceStep / TraceResponse
│   │   └── common.py              # ErrorResponse, HealthResponse
│   ├── services/
│   │   ├── __init__.py
│   │   ├── gemini_client.py       # Gemini API wrapper (init + call methods)
│   │   ├── firestore_client.py    # Firestore wrapper (init + CRUD helpers)
│   │   └── maps_client.py         # Google Maps Distance Matrix wrapper
│   └── api/
│       └── __init__.py            # (empty, endpoints added in later steps)
├── requirements.txt
└── .env.example
```

---

### Config & Environment

#### [NEW] [.env.example](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/.env.example)
Placeholder-only env file. Keys read at runtime via `pydantic-settings`.

```
GEMINI_API_KEY=
FIREBASE_SERVICE_ACCOUNT_PATH=
GOOGLE_MAPS_API_KEY=
BACKEND_CORS_ORIGINS=http://localhost:3000
```

#### [NEW] [config.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/config.py)
- Uses `pydantic-settings` `BaseSettings` to read from `.env`
- Fields: `GEMINI_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_PATH`, `GOOGLE_MAPS_API_KEY`, `BACKEND_CORS_ORIGINS`
- Validates that required keys are non-empty; raises clear error if missing

---

### FastAPI App

#### [NEW] [main.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/main.py)
- FastAPI app with `lifespan` context manager
- On startup: initialize Firebase Admin, Firestore client, Gemini client
- CORS middleware with origins from config
- `GET /health` → `{"status": "ok", "services": {"firestore": bool, "gemini": bool}}`
- All errors return the standard `ErrorResponse` shape from docs

---

### Firebase Auth

#### [NEW] [firebase_auth.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/auth/firebase_auth.py)
- FastAPI dependency `get_current_user(authorization: str = Header(...))`
- Extracts Bearer token, calls `firebase_admin.auth.verify_id_token(token)`
- Returns `uid` on success
- Returns 401 `ErrorResponse` on missing/invalid token with message `"auth_required"`

---

### Schemas (all matching docs/api_design.md exactly)

#### [NEW] [common.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/common.py)
```python
class HealthResponse(BaseModel):
    status: str
    services: dict[str, bool]

class ErrorResponse(BaseModel):
    error: str
    message: str
    code: int
```

#### [NEW] [parse_request.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/parse_request.py)
```python
class ParseRequestInput(BaseModel):
    user_id: str
    raw_text: str
    language_hint: str | None = None

class ParseRequestResponse(BaseModel):
    request_id: str
    service_type: str
    location_text: str | None
    urgency: str
    issue_summary: str
    parsed_ok: bool
```

#### [NEW] [providers.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/providers.py)
```python
class ProviderSearchRequest(BaseModel):
    request_id: str
    service_type: str
    user_lat: float
    user_lng: float
    urgency: str

class Provider(BaseModel):
    id: str
    name: str
    rating: float
    distance_km: float
    eta_minutes: int
    base_price: int
    available: bool
    rank_score: float
    explanation: str | None = None

class ProviderSearchResponse(BaseModel):
    providers: list[Provider]
    total_found: int
```

#### [NEW] [bookings.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/bookings.py)
```python
class BookingCreateRequest(BaseModel):
    request_id: str
    provider_id: str
    user_id: str
    time_slot: str

class BookingCreateResponse(BaseModel):
    booking_id: str
    status: str
    provider_name: str
    eta_minutes: int
    confirmation_text: str
    simulated: bool = True

class BookingStatusResponse(BaseModel):
    booking_id: str
    status: str
    provider_name: str
    eta_minutes: int
    last_updated: str
```

#### [NEW] [followups.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/followups.py)
```python
class FollowupRequest(BaseModel):
    booking_id: str
    trigger: str  # pre_arrival | completed | follow_up_review

class FollowupResponse(BaseModel):
    message: str
    send_at: str
```

#### [NEW] [traces.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/traces.py)
```python
class TraceStep(BaseModel):
    step: str
    input: dict
    output: dict
    timestamp: str

class TraceResponse(BaseModel):
    request_id: str
    steps: list[TraceStep]
```

---

### Service Clients

#### [NEW] [gemini_client.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/services/gemini_client.py)
- `GeminiClient` class
- `__init__(api_key)`: configures `google.generativeai` with API key
- `generate(system_prompt, user_prompt, max_tokens) → str`: calls `gemini-1.5-flash`, returns text response
- If API key missing → raises `ValueError` with clear message
- No retry logic for MVP

#### [NEW] [firestore_client.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/services/firestore_client.py)
- `FirestoreClient` class
- `__init__(service_account_path)`: initializes `firebase_admin` app + `firestore.client()`
- CRUD helpers: `add_document(collection, data)`, `get_document(collection, doc_id)`, `query_collection(collection, filters)`
- `log_trace(request_id, step_name, input_snapshot, output_snapshot, **kwargs)`: writes to `traces` collection
- If service account path missing → raises `ValueError`

#### [NEW] [maps_client.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/services/maps_client.py)
- `MapsClient` class
- `__init__(api_key)`: stores API key
- `get_distance_matrix(origin_lat, origin_lng, destinations: list[tuple]) → list[dict]`: calls Google Maps Distance Matrix API via `requests`, returns distance_km + eta_minutes per destination
- If API key missing → raises `ValueError`

---

### Dependencies

#### [NEW] [requirements.txt](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/requirements.txt)
```
fastapi>=0.111.0
uvicorn[standard]>=0.30.0
pydantic>=2.7.0
pydantic-settings>=2.3.0
google-generativeai>=0.7.0
firebase-admin>=6.5.0
requests>=2.32.0
python-dotenv>=1.0.0
```

---

## Verification Plan

### Automated Tests
1. `pip install -r requirements.txt` succeeds
2. `uvicorn app.main:app --host 0.0.0.0 --port 8000` starts without crash
3. `GET http://localhost:8000/health` returns `{"status": "ok", ...}`
4. Missing env vars produce clear error messages, not stack traces

### Manual Verification
- Confirm `.env.example` has **no real keys**
- Confirm all schemas match `docs/api_design.md` JSON shapes
