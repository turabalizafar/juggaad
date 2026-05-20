# Backend Alignment Fix — Walkthrough

## Changes Made

### 1. New User Profile Endpoint (`PUT/GET /api/v1/profile`)
- **[NEW]** [user_profile.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/user_profile.py) — `UserProfileInput` + `UserProfileResponse` schemas
- **[NEW]** [profile.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/api/endpoints/profile.py) — `PUT` creates/updates phone in `users/{uid}`, `GET` retrieves it
- **[MODIFY]** [router.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/api/router.py) — Registered profile router

### 2. GPS "Near Me" Fallback in `/parse`
- **[MODIFY]** [parse_request.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/parse_request.py) — Added `user_lat`/`user_lng` optional fields to `ParseInput`
- **[MODIFY]** [parse.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/api/endpoints/parse.py) — When `location_text` is null but GPS coords are present, auto-fills `"Current Location"`. Also stores coords in Firestore for downstream `/search`.

### 3. `issue_summary` Deterministic Fallback
- **[MODIFY]** [parse.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/api/endpoints/parse.py) — If Gemini returns null for `issue_summary`, fills it with `"{service_type} service request"`.

### 4. Booking Phone Auto-Fill
- **[MODIFY]** [bookings.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/schemas/bookings.py) — `user_phone_number` is now optional (`str | None = None`)
- **[MODIFY]** [book.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/api/endpoints/book.py) — If phone not sent, auto-fills from `users/{uid}` profile

### 5. Search Coordinate Fallback
- **[MODIFY]** [search.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/api/endpoints/search.py) — If `user_lat`/`user_lng` are `0.0`, reads stored coords from `service_requests/{request_id}` doc. Also replaced direct `request.user_lat` refs with resolved local variables.

### 6. Parse Token Limit
- **[MODIFY]** [parse.py](file:///c:/Users/Geo%20Computer/OneDrive/Desktop/Coding/juggaad/backend/app/api/endpoints/parse.py) — Increased `max_tokens` from 200 to 300 to prevent Gemini from truncating JSON.

---

## Test Results

E2E test (`scripts/test_e2e.py`) passed all 7 steps:

| Step | Feature | Result |
|------|---------|--------|
| 0 | Profile PUT + GET | ✅ Phone saved & retrieved |
| 1 | Parse (with location) | ✅ Intent extracted correctly |
| 1b | GPS "near me" parse | ✅ Location resolved to "Current Location" |
| 2 | Search & Rank | ✅ 23 providers found, top 3 ranked |
| 3 | Book (phone auto-fill) | ✅ Booking confirmed, phone auto-filled from profile |
| 4 | Follow-up | ✅ SMS reminder generated |
| 5 | History | ✅ Booking history retrieved |

---

## Frontend Guidance for Teammate

1. **Phone Dialog → `PUT /api/v1/profile`** with `{"phone_number": "+92...", "display_name": "..."}` after Google Auth
2. **GPS → attach `user_lat`/`user_lng`** to every `/parse` call using Flutter `geolocator` package
3. **Nullability → make `locationText`, `urgency`, `issueSummary` nullable** in Dart models
4. **Booking → `user_phone_number` is now optional** — can omit it, backend auto-fills from profile
5. **Phone format → use `+92` placeholders** instead of `+91`
