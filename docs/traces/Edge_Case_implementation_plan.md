# Fix 8 Edge-Case Bugs — Implementation Plan

## Overview

This plan addresses 8 user-reported bugs spanning the Flutter frontend and Python backend. The most impactful change is **Bug #2** — replacing the stateless parse-per-message approach with a **multi-turn AI chat agent** that maintains conversation context, so follow-up messages like "kal 10 bajy" are correctly understood as continuations of the previous request.

---

## Open Questions

> [!IMPORTANT]
> **Q1 — Conversation History Depth:** For the AI chat agent (Bug #2), how many past messages should we send to Gemini per turn? Sending the full chat history gives the best context but costs more tokens per call. I recommend **last 10 messages** as a sweet spot. Does that work for you?

> [!IMPORTANT]
> **Q2 — Dark Theme Persistence:** Should the dark theme preference survive app restarts (saved to SharedPreferences), or is it fine to reset to light on every launch?

> [!IMPORTANT]
> **Q3 — Service Completion Timer:** For Bug #5, should the "provider arrived" prompt appear after the ETA countdown finishes (e.g., 30 mins), or should we skip the timer for now and just add a manual "Mark as Arrived" button on the tracking screen?

---

## Proposed Changes

### Bug #1 — `display_name` is null in Firebase

**Root Cause:** The phone dialog in [login_screen.dart](file:///c:/juggaad/frontend/lib/screens/login_screen.dart#L131-L151) calls `updateProfile(phone)` but never passes `displayName`. The backend stores whatever is sent — since `display_name` is `None` in the request body, Firestore stores `null`.

#### [MODIFY] [login_screen.dart](file:///c:/juggaad/frontend/lib/screens/login_screen.dart)
- In `_submitPhone()`, read `FirebaseAuth.instance.currentUser?.displayName` and pass it to `updateProfile()`:
```dart
await ref.read(profileProvider.notifier).updateProfile(
  phone,
  displayName: FirebaseAuth.instance.currentUser?.displayName,
);
```

**No backend changes needed** — `profile.py` already accepts and stores `display_name`.

---

### Bug #2 — Conversational AI Chat Agent (Major Change)

**Root Cause:** Every message sent from the home screen calls `POST /parse` as a **brand new, stateless request**. There is no concept of "continuing a conversation." When the user types "kal 10 bajy" after being prompted for a time, it creates a fresh `request_id` and Gemini has no context that this is a follow-up.

**Solution:** Replace the stateless `/parse` call with a multi-turn `/chat` endpoint that:
1. Receives the full recent conversation history (user + assistant messages).
2. Sends it to Gemini as a multi-turn chat.
3. Gemini responds with either a structured JSON extraction (when all fields are present) OR a natural conversational reply asking for missing info.
4. The backend determines from Gemini's response whether to return `status: "complete"` or `status: "incomplete"`.

#### [NEW] Backend: `app/api/endpoints/chat.py`
New endpoint `POST /api/v1/chat` that accepts:
```python
class ChatInput(BaseModel):
    messages: list[ChatMessage]  # [{"role": "user"|"assistant", "content": "..."}]
    user_lat: float | None = None
    user_lng: float | None = None
```
- Constructs a multi-turn Gemini call with conversation history.
- System prompt instructs Gemini to either:
  - Extract structured JSON if all fields (service_type, location, urgency) are present across the conversation.
  - Reply conversationally in the same language (Urdu/Roman Urdu/English) if fields are still missing.
- Returns same `ParseResponse` schema so the rest of the pipeline (search → book → track) stays unchanged.

#### [NEW] Backend: `app/schemas/chat.py`
```python
class ChatMessage(BaseModel):
    role: str  # "user" or "assistant"
    content: str

class ChatInput(BaseModel):
    messages: list[ChatMessage]
    user_lat: float | None = None
    user_lng: float | None = None
```

#### [MODIFY] Backend: [router.py](file:///c:/juggaad/backend/app/api/router.py)
- Register the new `chat` router.

#### [MODIFY] Frontend: [api_service.dart](file:///c:/juggaad/frontend/lib/services/api_service.dart)
- Add new method `sendChat(messages, userLat, userLng)` that posts to `/chat`.

#### [MODIFY] Frontend: [chat_provider.dart](file:///c:/juggaad/frontend/lib/providers/chat_provider.dart)
- Instead of calling `apiService.parseRequest(rawText)`, build a `messages` list from the current `state` (converting `ChatMessage` objects to `{role, content}` maps) and call `apiService.sendChat(messages)`.
- On `incomplete` response, add the AI's reply to the chat and stay in `idle` state so the user can type another message naturally.
- On `complete` response, trigger `setParsedPreview(response)` as before.

#### [MODIFY] Frontend: [home_screen.dart](file:///c:/juggaad/frontend/lib/screens/home_screen.dart)
- The "Edit Prompt" button (from `parsed_request_screen.dart`) currently calls `setIdle()` and pops. When the user returns to the home screen and types a new message, it should continue the existing conversation — not start fresh. Since we're now sending the full chat history to `/chat`, this will work automatically.

#### [MODIFY] Frontend: [chat_message.dart](file:///c:/juggaad/frontend/lib/models/chat_message.dart)
- Add a `role` getter that maps `isUser` to `"user"` / `"assistant"`.

**Key Design Decision:** The old `/parse` endpoint remains untouched for backward compatibility. The new `/chat` endpoint is the only one the frontend will call going forward.

---

### Bug #3 — Dark Theme Toggle Not Working

**Root Cause:** In [user_profile_screen.dart](file:///c:/juggaad/frontend/lib/screens/user_profile_screen.dart#L228-L234), the `Switch` has `value: false` hardcoded and `onChanged` does nothing.

#### [NEW] Frontend: `lib/providers/theme_provider.dart`
- Create a `StateNotifierProvider<ThemeNotifier, ThemeMode>` that toggles between `ThemeMode.light` and `ThemeMode.dark`.

#### [MODIFY] [app_theme.dart](file:///c:/juggaad/frontend/lib/theme/app_theme.dart)
- Add a `static ThemeData get darkTheme` with the Stitch dark palette (inverted tones from the existing light theme).

#### [MODIFY] [main.dart](file:///c:/juggaad/frontend/lib/main.dart)
- Watch `themeProvider` and pass both `theme` and `darkTheme` to `MaterialApp`, along with `themeMode`.

#### [MODIFY] [user_profile_screen.dart](file:///c:/juggaad/frontend/lib/screens/user_profile_screen.dart)
- Wire the Switch to read/toggle `themeProvider`.

---

### Bug #4 — Tracking Screen Uses GPS Instead of Prompt Location

**Root Cause:** In [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart#L27-L58), the "user" marker is placed at `_userPosition` (device GPS). But the user's *intent* location is "Lahore DHA" or "Mandi Bahauddin" — the location they mentioned in their prompt.

**Solution:** The `ParsedIntent` has `locationText` (e.g. "Lahore DHA"). The backend `/search` endpoint already uses Google Maps to geocode and calculate distances from `user_lat/user_lng`. We need to **store the geocoded coordinates of the intent location** and use those on the tracking screen instead of live GPS.

#### [MODIFY] Backend: [search.py](file:///c:/juggaad/backend/app/api/endpoints/search.py)
- After geocoding or using the Maps Distance Matrix, store the **user_lat/user_lng that was actually used for distance calculation** into the Firestore `service_requests` doc as `search_origin_lat` and `search_origin_lng`.

#### [MODIFY] Frontend: [orchestration_provider.dart](file:///c:/juggaad/frontend/lib/providers/orchestration_provider.dart)
- Add `double? searchOriginLat` and `double? searchOriginLng` fields.
- In `searchProviders()`, after getting the response, use the `user_lat/user_lng` that were passed to `/search` and store them.

#### [MODIFY] Frontend: [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart)
- Instead of calling `locationService.getCurrentPosition()`, read `orchestrationNotifier.searchOriginLat/Lng` (the coordinates used for the search).
- Fallback to live GPS only if those are null.

---

### Bug #5 — Follow-up Button Has No Lifecycle

**Root Cause:** The follow-up button in [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart#L257-L264) fires `sendFollowup()` and shows a SnackBar, but there's no state progression — no "arrived", "in-progress", "completed", or "rate" flow.

**Solution:** Add a simple state machine to the tracking screen:

#### [MODIFY] Frontend: [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart)
- Add a local `_trackingPhase` enum: `waiting → arrived → inProgress → completed`.
- The bottom action area changes based on phase:
  - **waiting**: "Send Follow-up" button (existing) + countdown timer showing remaining ETA.
  - **arrived**: "Provider Has Arrived" banner + "Start Service" button.
  - **inProgress**: "Service in Progress" banner + "Mark as Completed" button.
  - **completed**: Rating stars (1-5) + "Submit & Go Home" button.
- After submitting rating, call `setIdle()` and `popUntil(isFirst)` to return home.
- The timeline widget updates its active/completed states based on `_trackingPhase`.

> [!NOTE]
> Since there is no real-time provider tracking, the phase transitions will be triggered by user taps (manual flow). The ETA countdown is cosmetic — when it reaches 0, we prompt with "Has your provider arrived?" and a Yes/No button.

---

### Bug #6 — History Screen: Tap Active Booking → Show Tracking

**Root Cause:** The `_BookingCard` in [booking_history_screen.dart](file:///c:/juggaad/frontend/lib/screens/booking_history_screen.dart) has no `onTap` handler.

#### [MODIFY] Frontend: [booking_history_screen.dart](file:///c:/juggaad/frontend/lib/screens/booking_history_screen.dart)
- Wrap `_BookingCard` in a `GestureDetector` / `InkWell`.
- On tap, if `booking.status` is NOT `completed` or `cancelled`:
  - Fetch the booking details from the backend (we can reuse `getBookingStatus()`).
  - Populate orchestration state with the booking data.
  - Navigate to `TrackingScreen`.
- If `completed`, show a dialog with the booking summary.

> [!WARNING]
> This requires the tracking screen to accept booking data **independently** of the orchestration flow (since the user didn't just go through parse → search → book). I'll add an alternative constructor or pass the data via route arguments.

---

### Bug #7 — Phone Dialog Can Be Dismissed

**Root Cause:** In [login_screen.dart](file:///c:/juggaad/frontend/lib/screens/login_screen.dart#L38-L45), the phone dialog is shown via `showModalBottomSheet` which is dismissible by default (swipe down or tap outside).

#### [MODIFY] Frontend: [login_screen.dart](file:///c:/juggaad/frontend/lib/screens/login_screen.dart)
- Add `isDismissible: false` and `enableDrag: false` to `showModalBottomSheet()`.
- Also override `WillPopScope` (or `PopScope`) inside the dialog to prevent the back button from closing it.

---

### Bug #8 — Call Buttons Don't Work

**Root Cause:** The call button `onPressed` callbacks in [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart#L243) and [booking_confirmation_screen.dart](file:///c:/juggaad/frontend/lib/screens/booking_confirmation_screen.dart#L157-L159) are empty `() {}`.

#### [MODIFY] [pubspec.yaml](file:///c:/juggaad/frontend/pubspec.yaml)
- Add `url_launcher: ^6.3.1` dependency.

#### [MODIFY] Frontend: [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart)
- Import `url_launcher` and call `launchUrl(Uri.parse('tel:${provider.phoneNumber}'))`.

#### [MODIFY] Frontend: [booking_confirmation_screen.dart](file:///c:/juggaad/frontend/lib/screens/booking_confirmation_screen.dart)
- Same: `launchUrl(Uri.parse('tel:${bookResponse.providerPhone}'))`.

---

## Verification Plan

### Automated
```bash
cd c:\juggaad\frontend
flutter analyze    # Zero issues expected
```

### Manual Testing (on Pixel 7 via ADB)
| Bug | Test Steps | Expected Result |
|-----|-----------|-----------------|
| #1 | Sign in → Enter phone → Check Firebase `users` collection | `display_name` shows Google name |
| #2 | Type "mujhy plumber chahiye" → AI asks for location → Type "Lahore" → AI asks for time → Type "kal" | All 3 messages stay in one conversation; final response shows complete intent |
| #3 | Go to Profile → Toggle Dark Theme switch | Entire app switches to dark palette |
| #4 | Request service in "Lahore DHA" (while physically in Gujrat) → Book → Track | Map shows pin on Lahore DHA, not Gujrat |
| #5 | On tracking screen → Wait for ETA countdown → Tap "Provider Arrived" → Complete → Rate | Full lifecycle completes, returns to home |
| #6 | Go to History → Tap an in-progress booking | Opens tracking screen with that booking |
| #7 | Sign in → Try swiping down the phone dialog | Dialog stays, cannot be dismissed |
| #8 | On tracking screen → Tap call icon | Phone app opens with provider's number |
