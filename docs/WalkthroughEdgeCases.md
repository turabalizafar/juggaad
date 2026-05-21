# Walkthrough — 8 Edge-Case Bug Fixes

## Summary

All 8 bugs have been fixed across 14 files (6 new/rewritten, 8 modified). Flutter analyze passes with **zero issues**. Backend syntax verified clean.

---

## Bug #1 — `display_name` null in Firebase

**Root cause:** [login_screen.dart](file:///c:/juggaad/frontend/lib/screens/login_screen.dart) called `updateProfile(phone)` without passing the Google account name.

**Fix:** Read `FirebaseAuth.instance.currentUser?.displayName` and pass it as the `displayName` parameter.

---

## Bug #2 — Conversational AI Chat Agent (Major)

**Root cause:** Every user message was a stateless `POST /parse` call. Follow-up messages like "kal 10 bajy" were treated as brand new requests with no context.

**Fix:** Created a new multi-turn `POST /api/v1/chat` endpoint:

| File | Change |
|------|--------|
| [chat.py (schema)](file:///c:/juggaad/backend/app/schemas/chat.py) | **[NEW]** Pydantic models for chat messages and response |
| [chat.py (endpoint)](file:///c:/juggaad/backend/app/api/endpoints/chat.py) | **[NEW]** Multi-turn Gemini endpoint with conversation history (last 8 messages), off-topic rejection, and language-matching replies |
| [router.py](file:///c:/juggaad/backend/app/api/router.py) | Registered `/chat` route |
| [api_service.dart](file:///c:/juggaad/frontend/lib/services/api_service.dart) | Added `sendChat()` method |
| [chat_message.dart](file:///c:/juggaad/frontend/lib/models/chat_message.dart) | Added `role` getter and `toApiMap()` |
| [chat_provider.dart](file:///c:/juggaad/frontend/lib/providers/chat_provider.dart) | **Rewritten** to send full conversation history to `/chat` instead of `/parse` |

**Key safeguard:** The system prompt explicitly rejects off-topic messages (jokes, general chat) with a polite redirect to service requests only.

---

## Bug #3 — Dark Theme Toggle

**Root cause:** Switch was hardcoded to `value: false` with empty `onChanged`.

**Fix:**

| File | Change |
|------|--------|
| [theme_provider.dart](file:///c:/juggaad/frontend/lib/providers/theme_provider.dart) | **[NEW]** StateNotifier with `SharedPreferences` persistence |
| [app_theme.dart](file:///c:/juggaad/frontend/lib/theme/app_theme.dart) | Added `darkTheme` getter with inverted Stitch palette |
| [main.dart](file:///c:/juggaad/frontend/lib/main.dart) | Wired `themeMode` from provider, passes both themes to `MaterialApp` |
| [user_profile_screen.dart](file:///c:/juggaad/frontend/lib/screens/user_profile_screen.dart) | Switch reads/toggles `themeProvider` |

Theme preference **survives app restarts** via `SharedPreferences`.

---

## Bug #4 — Map Shows GPS Instead of Prompt Location

**Root cause:** Tracking screen fetched device GPS for the "You" marker, but the user requested service in a different city.

**Fix:**

| File | Change |
|------|--------|
| [orchestration_provider.dart](file:///c:/juggaad/frontend/lib/providers/orchestration_provider.dart) | Added `searchOriginLat/Lng` fields, stored during `searchProviders()` |
| [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart) | Uses `orchestrationNotifier.searchOriginLat/Lng` instead of live GPS |

The marker now shows "Service Location" at the location mentioned in the prompt.

---

## Bug #5 — Follow-up Button Lifecycle

**Root cause:** Follow-up button only showed a SnackBar and had no state progression.

**Fix:** [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart) **rewritten** with a `TrackingPhase` state machine:

```
waiting → arrived → inProgress → completed (with rating)
```

- **waiting:** Shows static ETA info, "Send Follow-up" + "Provider Has Arrived" buttons
- **arrived:** "Provider has arrived!" banner + "Service Started" button
- **inProgress:** "Service in progress..." banner + "Mark as Completed" button
- **completed:** Star rating (1–5) + "Submit & Go Home" button → returns to home

---

## Bug #6 — History: Tap Active Booking

**Root cause:** `_BookingCard` had no `onTap` handler.

**Fix:** [booking_history_screen.dart](file:///c:/juggaad/frontend/lib/screens/booking_history_screen.dart):
- Cards wrapped in `GestureDetector`
- **Active bookings:** Show info dialog with service details + call button
- **Completed bookings:** Show summary dialog
- **Cancelled bookings:** Show SnackBar

---

## Bug #7 — Phone Dialog Dismissible

**Root cause:** `showModalBottomSheet` was dismissible by default.

**Fix:** [login_screen.dart](file:///c:/juggaad/frontend/lib/screens/login_screen.dart):
- `isDismissible: false` and `enableDrag: false`
- Dialog content wrapped in `PopScope(canPop: false)` to block back button

---

## Bug #8 — Call Buttons Non-Functional

**Root cause:** `onPressed: () {}` empty callbacks.

**Fix:**
- Added `url_launcher: ^6.3.1` to [pubspec.yaml](file:///c:/juggaad/frontend/pubspec.yaml)
- [tracking_screen.dart](file:///c:/juggaad/frontend/lib/screens/tracking_screen.dart): `launchUrl(Uri.parse('tel:${provider.phoneNumber}'))`
- [booking_confirmation_screen.dart](file:///c:/juggaad/frontend/lib/screens/booking_confirmation_screen.dart): Same for `bookResponse.providerPhone`

---

## Verification

- ✅ `flutter pub get` — resolved successfully
- ✅ `flutter analyze` — 0 issues
- ✅ Backend Python syntax — clean compile
- ⏳ Backend needs restart (uvicorn reload should auto-detect new files)

## Testing Checklist

| Bug | How to Test |
|-----|-------------|
| #1 | Sign in → Enter phone → Check Firebase `users/{uid}` for `display_name` |
| #2 | Chat: "plumber chahiye" → AI asks location → "Lahore" → AI asks time → "kal" → Shows parsed intent |
| #3 | Profile → Toggle Dark Theme → App switches themes. Restart app → preference persists |
| #4 | Request service in "Lahore DHA" while in Gujrat → Map pin at Lahore, not Gujrat |
| #5 | Tracking → "Provider Has Arrived" → "Service Started" → "Mark Completed" → Rate → Goes home |
| #6 | History → Tap active booking → Info dialog with call button |
| #7 | Login → Phone dialog → Try swipe/back → Cannot dismiss |
| #8 | Tracking/Confirmation → Tap call icon → Phone app opens |
