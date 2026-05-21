# Fix 6 More Edge-Case Bugs — Implementation Plan

## Overview

These fixes address cleanup from the architecture migration, a critical map pin bug, and several UX issues around error handling and navigation flow.

---

## Open Questions

> [!IMPORTANT]
> **Q1 — Geocoding API:** To fix the pin bug properly, I need to add a **Google Maps Geocoding API** call on the backend to convert `location_text` (e.g., "DHA Lahore") into lat/lng coordinates. This uses the same Maps API key you already have. The Geocoding API must be **enabled** in your Google Cloud Console. Is it already enabled, or should I add the enable step to the plan?

> [!IMPORTANT]
> **Q2 — History Refresh:** When the user exits the tracking screen mid-flow (without completing), should the booking show as "confirmed" (its actual status) in history, or should we add a separate "in_progress" status?

---

## Proposed Changes

### Bug #1 — Delete Deprecated `/parse` Endpoint

The old stateless `/parse` endpoint is no longer called by any frontend code (we switched to `/chat`). Keeping it risks confusion and accidental use.

#### [DELETE] Backend: [parse.py](file:///c:/juggaad/backend/app/api/endpoints/parse.py)
Delete the entire file.

#### [DELETE] Backend: [parse_request.py](file:///c:/juggaad/backend/app/schemas/parse_request.py)
Delete the entire file — `ParseInput`, `ParsedIntent`, `ParseResponse` schemas are now unused on the backend.

#### [MODIFY] Backend: [router.py](file:///c:/juggaad/backend/app/api/router.py)
- Remove `from app.api.endpoints.parse import router as parse_router`
- Remove `api_router.include_router(parse_router, ...)`

#### [MODIFY] Frontend: [api_service.dart](file:///c:/juggaad/frontend/lib/services/api_service.dart)
- Delete the `parseRequest()` method (lines 38–51). Nobody calls it anymore.

> [!NOTE]
> The frontend `ParseResponse` and `ParsedIntent` models in `lib/models/` are **still used** by the `/chat` response and orchestration flow, so they stay. Only the backend parse schemas and endpoint are deleted.

---

### Bug #2 — Theme Consistency Across All Screens

All screens already use `Theme.of(context).colorScheme` which automatically respects the teal/amethyst palette. The only issues are:

- **Login screen**: Uses a generic `Icons.bolt` in a container as logo instead of the SVG brand mark
- **Home screen AppBar**: Uses `Icons.bolt` icon — should use SVG logo
- **Bottom Navigation Bar**: Needs explicit background color for dark mode

#### [MODIFY] [login_screen.dart](file:///c:/juggaad/frontend/lib/screens/login_screen.dart)
- Replace the bolt icon Container (lines 65-86) with `SvgPicture.asset('lib/assets/Juggaad.svg')`.

#### [MODIFY] [home_screen.dart](file:///c:/juggaad/frontend/lib/screens/home_screen.dart)
- Replace `Icon(Icons.bolt)` in AppBar with a small `SvgPicture.asset`.

#### [MODIFY] [main_shell.dart](file:///c:/juggaad/frontend/lib/screens/main_shell.dart)
- Add explicit `backgroundColor` to `BottomNavigationBar` from `colorScheme.surface` so it looks correct in both light and dark modes.

---

### Bug #3 — Set App Logo as Juggaad.svg

#### [MODIFY] [pubspec.yaml](file:///c:/juggaad/frontend/pubspec.yaml)
- Register the asset:
```yaml
flutter:
  assets:
    - lib/assets/Juggaad.svg
```

This is needed for `SvgPicture.asset()` to find the file. The `flutter_svg` package is already in pubspec.

The actual SVG rendering is handled in Bug #2 changes above.

---

### Bug #4 — Fix Map Pins (CRITICAL — Root Cause Analysis)

**Root Cause:** The current flow sends **device GPS coordinates** as `user_lat/user_lng` to `/search`. The `/search` endpoint uses these GPS coords as the "origin" for the Distance Matrix API call and for calculating distances. The tracking screen then reads `searchOriginLat/Lng` which are... the device GPS coords. 

So even though the user said "DHA Lahore", the origin for distance calculation and the map pin are both at the user's physical location (Gujrat).

**The Fix:** The backend needs to **geocode** the `location_text` (e.g., "DHA Lahore") into lat/lng coordinates using the Google Maps Geocoding API, and use THOSE coordinates as the search origin — NOT the device GPS. Device GPS should **only** be used when the user explicitly says "near me", "mere ghar", "my location", etc.

#### [MODIFY] Backend: [maps_client.py](file:///c:/juggaad/backend/app/services/maps_client.py)
- Add a new method `geocode(address: str) -> tuple[float, float] | None` that calls the Google Maps Geocoding API.

#### [MODIFY] Backend: [chat.py](file:///c:/juggaad/backend/app/api/endpoints/chat.py)
- Update the system prompt to instruct Gemini: if user says "near me", "mere ghar", "my location", set `location_text` to the special value `"__CURRENT_LOCATION__"`.
- For all other locations (named places like "DHA Lahore", "Mandi Bahauddin"), set `location_text` to the actual address text.

#### [MODIFY] Backend: [search.py](file:///c:/juggaad/backend/app/api/endpoints/search.py)
- **Before** calculating distances:
  - If `location_text == "__CURRENT_LOCATION__"` → use device GPS (`user_lat/user_lng`) as origin.
  - Otherwise → call `maps_client.geocode(location_text)` to get the geocoded lat/lng and use THOSE as the origin.
- Store the **actual origin coordinates used** (geocoded or GPS) in the Firestore `service_requests` doc as `search_origin_lat` and `search_origin_lng`.
- Return `search_origin_lat` and `search_origin_lng` in the `SearchResponse` schema.

#### [MODIFY] Backend: [providers.py](file:///c:/juggaad/backend/app/schemas/providers.py)
- Add `search_origin_lat: float | None = None` and `search_origin_lng: float | None = None` to `SearchResponse`.

#### [MODIFY] Frontend: [search_response.dart](file:///c:/juggaad/frontend/lib/models/search_response.dart)
- Add `searchOriginLat` and `searchOriginLng` fields. Parse from JSON.

#### [MODIFY] Frontend: [orchestration_provider.dart](file:///c:/juggaad/frontend/lib/providers/orchestration_provider.dart)
- In `searchProviders()`, after getting the response, read `response.searchOriginLat/Lng` (returned by backend) and store them as `searchOriginLat/Lng` instead of storing the device GPS. This ensures the tracking screen map pins use the geocoded coordinates.

---

### Bug #5 — Multi-Service / Multi-Location 400 Error Handling

**Root Cause:** When a user sends something like "mujhy plumber aur electrician chahiye Lahore aur Islamabad mein", Gemini may produce malformed JSON (e.g., two intents), or the backend throws an unhandled exception which results in a raw 400 error bubbling up to the frontend as `DioException [bad response]`.

**Fix — Two layers:**

#### [MODIFY] Backend: [chat.py](file:///c:/juggaad/backend/app/api/endpoints/chat.py)
- Update the system prompt with a new rule:
```
9. If the user asks for MULTIPLE services or MULTIPLE locations in one message, respond with:
   {"status": "incomplete", "missing_fields": [], "ai_message": "Ek waqt mein sirf ek service request karein. Pehle batayein kaunsi service chahiye?"}
```
- This instructs Gemini to handle it gracefully as an "incomplete" response rather than trying to extract multiple intents.
- The existing `except` block (line 122-129) already catches JSON parse errors and returns a 400. **Improve it** to return a user-friendly chat message instead of throwing an HTTP error:
  - Instead of `raise HTTPException(400)`, return a `ChatResponse` with `status="incomplete"` and `ai_message="Sorry, mujhe samajh nahi aaya. Kripya dobara try karein."` so the frontend shows it in the chat instead of crashing.

#### [MODIFY] Frontend: [chat_provider.dart](file:///c:/juggaad/frontend/lib/providers/chat_provider.dart)
- Improve the `catch` block to show a cleaner error message instead of raw `DioException` text:
```dart
catch (e) {
  orchestrationNotifier.setIdle();
  String errorMsg = 'Something went wrong. Please try again.';
  if (e is DioException && e.response?.data != null) {
    errorMsg = e.response?.data['detail'] ?? errorMsg;
  }
  state = [...state, ChatMessage(text: errorMsg, isUser: false)];
}
```

---

### Bug #6 — Tracking Screen Blocks Exit + Orders Missing from History

**Two sub-problems:**

**A) User is trapped on tracking screen:** The close (X) button calls `setIdle()` + `popUntil(isFirst)`, which resets ALL orchestration state including `bookResponse`. This works for going home, but the booking still exists in Firebase with status "confirmed". This is fine — the booking *should* stay as "confirmed" in the database.

**B) Order doesn't appear in history after pressing back:** The history screen uses `FutureProvider` which caches its first fetch. After navigating back from tracking, the stale cache shows old data. Need to **invalidate** the history cache when returning.

#### [MODIFY] Frontend: [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart)
- On the close (X) button:
  - Remove `setIdle()` call — don't clear orchestration state aggressively.
  - Instead, just `popUntil(isFirst)` to go home.
  - The user can always start a new request from the home screen, which calls `setIdle()` naturally when `setParsing()` fires.
  - **But:** We also need to call `ref.invalidate(historyBookingsProvider)` so the history tab refetches fresh data.

- On the "Submit & Go Home" button (after rating):
  - Keep existing `setIdle()` + `popUntil(isFirst)` behavior.
  - **Also** invalidate history provider.

#### [MODIFY] Frontend: [booking_confirmation_screen.dart](file:///c:/juggaad/frontend/lib/screens/booking_confirmation_screen.dart)
- On "View Tracking" navigation, DON'T block back navigation — ensure the user can press back to go to the confirmation screen and then back more to go home.

#### [MODIFY] Frontend: [booking_history_screen.dart](file:///c:/juggaad/frontend/lib/screens/booking_history_screen.dart)
- Add a **pull-to-refresh** or automatic refresh when the tab becomes visible. The simplest approach: change from `FutureProvider` to calling `ref.invalidate(historyBookingsProvider)` in `initState` or `didChangeDependencies`.

---

## Verification Plan

### Automated
```bash
cd c:\juggaad\frontend
flutter analyze    # Zero issues expected
```

### Manual Testing
| Bug | Test Steps | Expected Result |
|-----|-----------|-----------------|
| #1 | Start backend → Check `/docs` → No `/parse` endpoint | Endpoint removed |
| #2 | Check login, home, all screens in both light/dark | Consistent teal+amethyst palette, SVG logo visible |
| #3 | Check login + home screen | Juggaad.svg logo displayed |
| #4 | Prompt "plumber chahiye DHA Lahore" → Book → Track | Map pins in Lahore area, NOT Gujrat |
| #4b | Prompt "plumber chahiye mere ghar pe abhi" | Uses GPS (Gujrat), pins at Gujrat |
| #5 | Send "mujhy plumber aur electrician chahiye" | AI replies "ek waqt mein sirf ek service" — no crash |
| #6 | Book → Tracking screen → Press X → Go to History tab | Booking visible with "confirmed" status |
| #6b | Book → Full flow → Rate → Submit → History | Booking visible with "confirmed" status |
