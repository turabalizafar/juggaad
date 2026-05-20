# Backend–Frontend Alignment Fix Plan

This plan addresses the four conflicts identified in `alignment_analysis.md` plus the two new gaps you raised (phone number storage, device location).

---

## Conflict Summary

| # | Issue | Root Cause | Who Changes |
|---|-------|-----------|-------------|
| B | Phone format `+91` in frontend | Frontend placeholders are Indian | **Frontend only** |
| C | `ParsedIntent` nullability mismatch | Backend sends nulls, frontend expects non-null | **Both** (see details) |
| New-1 | No endpoint to save user phone after Google Auth | Backend has no `users` collection or `/profile` route | **Backend** |
| New-2 | "near me" prompts have no device location | `/parse` doesn't accept lat/lng; `/search` requires them manually | **Both** |

> [!NOTE]
> Conflict A (theme colors) is purely a frontend/Stitch concern and is excluded per your instructions.

---

## Conflict C Decision: Make Backend Stricter

> [!IMPORTANT]  
> **Recommendation: Keep the backend nullable, but make the frontend handle nulls gracefully.**
>
> Making `urgency`, `location_text`, and `issue_summary` mandatory in the backend schema would break the entire "incomplete → ask user" flow that `/parse` is designed around. The whole point of returning `status: "incomplete"` with `missing_fields` is that Gemini couldn't extract those fields. If we made them mandatory, we'd have to fabricate fake values, which defeats the purpose.

### What changes:

**Backend (no schema change needed):**
- The `ParsedIntent` schema already correctly declares these as `str | None = None`. This is correct and must stay.
- However, `issue_summary` currently defaults to `None`, but Gemini almost always returns *something* for it. We should add a deterministic fallback in `parse.py` so it never arrives as `null` in the response:
  ```python
  if not intent.issue_summary:
      intent.issue_summary = intent.service_type.replace("_", " ") + " service request"
  ```

**Frontend action:**
- Update `parsed_intent.dart` model to declare `locationText`, `urgency`, and `issueSummary` as nullable (`String?`).
- Use null-aware operators in UI widgets (e.g., `intent.locationText ?? "Not specified"`).

---

## New-1: User Profile & Phone Number Storage

### Problem
After Google Sign-In, a dialog prompts the user to enter their phone number. Currently:
- There is **no `/profile` endpoint** in the backend.
- There is **no `users` collection** in Firestore.
- The `user_phone_number` field in `BookRequest` is sent by the frontend at booking time, but there's nowhere to persist it after initial sign-up.

### Proposed Backend Changes

#### [NEW] `backend/app/schemas/user_profile.py`
```python
class UserProfileInput(BaseModel):
    phone_number: str          # "+923001234567"
    display_name: str | None = None

class UserProfileResponse(BaseModel):
    uid: str
    phone_number: str
    display_name: str | None = None
    created_at: str
```

#### [NEW] `backend/app/api/endpoints/profile.py`
Two endpoints:

| Method | Path | Purpose |
|--------|------|---------|
| `PUT` | `/api/v1/profile` | Create or update user profile (called after Google Auth phone dialog) |
| `GET` | `/api/v1/profile` | Retrieve current user's profile |

Logic:
1. `PUT /api/v1/profile` — Takes `phone_number` (and optional `display_name`) from the request body. Writes to Firestore `users/{uid}` document. If the doc already exists, it updates; if not, it creates.
2. `GET /api/v1/profile` — Reads `users/{uid}` and returns the profile. Returns 404 if the user hasn't completed onboarding.

#### [MODIFY] `backend/app/api/router.py`
Register the new `profile` router.

#### [MODIFY] `backend/app/api/endpoints/book.py`
Currently, `user_phone_number` is a required field in `BookRequest`. After this change:
- Make `user_phone_number` **optional** in `BookRequest` (`str | None = None`).
- If the frontend doesn't send it, the backend will look it up from `users/{uid}` in Firestore automatically.
- This means the frontend can either pass it explicitly or let the backend resolve it from the profile.

### Frontend action:
- After Google Sign-In, show the phone dialog.  
- On submit, call `PUT /api/v1/profile` with the phone number.
- On the booking screen, either pass `user_phone_number` from local state or omit it (backend auto-fills from profile).

---

## New-2: Device Location for "near me" Queries

### Problem
When a user says *"AC technician near me"*, Gemini correctly extracts `location_text: null` (because no specific area was named). The current flow then returns `status: "incomplete"` and asks the user to type their location. But the app *already has* the device's GPS coordinates — it should use them automatically.

### Proposed Solution

> [!IMPORTANT]
> The fix here is a **frontend-first** approach. The backend `/search` endpoint already accepts `user_lat` and `user_lng`. The gap is that `/parse` doesn't receive or forward coordinates, and the frontend doesn't send them.

#### [MODIFY] `backend/app/schemas/parse_request.py` — `ParseInput`
Add two optional fields:
```python
class ParseInput(BaseModel):
    raw_text: str
    language_hint: str | None = None
    user_lat: float | None = None    # NEW — device GPS latitude
    user_lng: float | None = None    # NEW — device GPS longitude
```

#### [MODIFY] `backend/app/api/endpoints/parse.py`
After Gemini extraction, if `location_text` is missing **but** `user_lat`/`user_lng` are provided:
1. **Don't** mark `location_text` as a missing field.
2. Set `location_text` to `"Current Location"` (deterministic, no AI).
3. Store the coordinates in the Firestore `service_requests` document so `/search` can use them later.

This means the flow becomes:
- User says "AC technician near me" → frontend sends `{raw_text: "...", user_lat: 31.47, user_lng: 74.41}`
- Gemini returns `location_text: null`
- Backend sees coordinates are present → sets `location_text = "Current Location"`, stores lat/lng
- Returns `status: "complete"` instead of `"incomplete"`
- Frontend proceeds directly to `/search` using those same coordinates

#### [MODIFY] `backend/app/api/endpoints/search.py`
Add a fallback: if `user_lat`/`user_lng` are `0` or missing in the search request, try to read them from the stored `service_requests/{request_id}` document. This handles the case where the frontend passes coordinates once (during `/parse`) and they carry forward automatically.

### Frontend action:
- Request location permission on app start (or on first prompt).
- Always attach `user_lat` / `user_lng` to the `/parse` request body if GPS is available.
- When calling `/search`, use the same coordinates.

---

## Files Changed (Backend Only)

| File | Action | What |
|------|--------|------|
| `app/schemas/user_profile.py` | **NEW** | `UserProfileInput` + `UserProfileResponse` |
| `app/api/endpoints/profile.py` | **NEW** | `PUT` + `GET /api/v1/profile` |
| `app/api/router.py` | **MODIFY** | Register profile router |
| `app/schemas/parse_request.py` | **MODIFY** | Add `user_lat`, `user_lng` to `ParseInput` |
| `app/api/endpoints/parse.py` | **MODIFY** | Handle GPS fallback for missing `location_text` + `issue_summary` fallback |
| `app/schemas/bookings.py` | **MODIFY** | Make `user_phone_number` optional in `BookRequest` |
| `app/api/endpoints/book.py` | **MODIFY** | Auto-fill `user_phone_number` from profile if not provided |
| `app/api/endpoints/search.py` | **MODIFY** | Fallback to stored lat/lng from service_requests doc |
| `scripts/test_e2e.py` | **MODIFY** | Add profile + GPS test steps |

---

## Frontend Guidance Summary (for your teammate)

1. **Conflict B:** Change phone placeholders from `+91` to `+92` format.
2. **Conflict C:** Make `locationText`, `urgency`, `issueSummary` nullable in Dart models. Use `?? "default"` in widgets.
3. **Phone dialog:** After Google Auth, call `PUT /api/v1/profile` with the entered phone number.
4. **GPS:** Use `geolocator` package to get device location. Attach `user_lat`/`user_lng` to every `/parse` call.
5. **Booking:** Can omit `user_phone_number` from `/book` request — backend will auto-fill from profile.

---

## Verification Plan

### Automated Tests
- Update `scripts/test_e2e.py` to cover:
  1. `PUT /api/v1/profile` — save phone number
  2. `GET /api/v1/profile` — retrieve it
  3. `/parse` with `user_lat`/`user_lng` — verify `"near me"` resolves to `status: "complete"`
  4. `/parse` without coordinates — verify it still returns `status: "incomplete"` with `missing_fields: ["location_text"]`
  5. `/book` without `user_phone_number` — verify backend auto-fills from profile

### Manual Verification
- Once teammate pulls, test the full Flutter flow: Google Auth → Phone Dialog → Chat → "near me" prompt → Search → Book.
