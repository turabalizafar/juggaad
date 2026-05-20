# Juggaad Flutter Frontend — Implementation Plan

This plan details the complete frontend implementation for the Jugaad AI Service Orchestrator, incorporating all conflict resolutions from [implementation_alignment_plan.md](file:///d:/juggaad/docs/traces/implementation_alignment_plan.md) and the user's confirmed decisions.

> [!NOTE]
> **Backend is complete.** This plan covers **frontend-only** work. All screens are built one-by-one with user consent before proceeding to the next.

---

## Conflict Resolutions (Confirmed)

| Conflict | Resolution |
|:---|:---|
| **A: Theme Colors** | Use exact Stitch palette: Primary `#006768`, Tertiary `#7543A7`, and full Material3 token set from the Stitch Tailwind config |
| **B: Phone Format** | Use Pakistani format `+92 300 1234567` in all placeholders — NOT `+91` |
| **C: Nullability** | Keep frontend fields **non-nullable** with default fallbacks (e.g. `json['urgency'] ?? 'flexible'`, `json['location_text'] ?? 'Not specified'`) so that null JSON values are safely handled without crashing |
| **New-1: User Profile** | After Google Sign-In → show phone number dialog → call `PUT /api/v1/profile` with phone number to persist |
| **New-2: Device Location** | Use `geolocator` package → attach `user_lat`/`user_lng` to every `/parse` request → enables "near me" queries |
| **Auth** | Use **real Firebase Auth** (Google Sign-In). No mock tokens |
| **StreamBuilder Animation** | Use `Future.delayed` (~500ms) between trace step animations for smooth UX |

---

## Stitch Screen → Flutter Screen Mapping

| # | Stitch Screen Title | Stitch Screen ID | Flutter File | Backend Endpoint |
|:--|:---|:---|:---|:---|
| 1 | Login - Teal & Amethyst | `089cceaf...` | `login_screen.dart` | Firebase Auth (Google) |
| 2 | Login - Phone Number Prompt | `49178bfe...` | Dialog within `login_screen.dart` | `PUT /api/v1/profile` |
| 3 | Home - AI Chat Interface | `197b90ff...` | `home_screen.dart` | `POST /api/v1/parse` |
| 4 | Request Preview - Teal & Amethyst | `1f8b8784...` | `parsed_request_screen.dart` | — (displays `/parse` result) |
| 5 | Provider List - Updated Nav | `fff24ae9...` | `provider_results_screen.dart` | `POST /api/v1/search` |
| 6 | Booking Confirmation - Teal & Amethyst | `154cc164...` | `booking_confirmation_screen.dart` | `POST /api/v1/book` |
| 7 | Tracking - Teal & Amethyst | `55ee8447...` | `tracking_screen.dart` | `GET /api/v1/booking/{id}`, `POST /api/v1/followup` |
| 8 | Booking History - Cleaned | `e2af0be4...` | `booking_history_screen.dart` | `GET /api/v1/history/requests`, `GET /api/v1/history/bookings` |
| 9 | User Profile | `8f518c3c...` | `user_profile_screen.dart` | `GET /api/v1/profile` |

---

## Proposed Changes

### Phase 0: Foundation (Theme + Models + Services)

#### [MODIFY] [app_theme.dart](file:///d:/juggaad/frontend/lib/theme/app_theme.dart)
- Replace all color constants with exact Stitch Material3 tokens:
  - `primary`: `#006768`, `primaryContainer`: `#008283`
  - `tertiary`: `#7543A7`, `tertiaryContainer`: `#905DC2`
  - `secondary`: `#426464`, `secondaryContainer`: `#C4EAE9`
  - `surface`: `#F6FAFA`, `background`: `#F6FAFA`
  - `onSurface`: `#171C1D`, `onSurfaceVariant`: `#3D4949`
  - `outline`: `#6D7979`, `outlineVariant`: `#BDC9C8`
  - `error`: `#BA1A1A`, `inversePrimary`: `#71D6D7`
  - `surfaceContainerLowest`: `#FFFFFF`, `surfaceContainerLow`: `#F0F4F4`
  - `surfaceContainer`: `#EAEFEE`, `surfaceContainerHigh`: `#E5E9E9`
- Use `Inter` font family at all text styles matching Stitch: `headline-lg` (32/40/700), `headline-md` (24/32/600), `body-md` (16/24/400), `label-md` (14/20/500)
- Set `borderRadius` to match Stitch: default `4px`, lg `8px`, xl `12px`, full `9999px`

---

#### [NEW] `lib/models/agent_trace.dart`
```dart
class AgentTrace {
  final String step;
  final String message;
  final String timestamp;
  // fromJson with non-nullable defaults
}
```

#### [MODIFY] [parsed_intent.dart](file:///d:/juggaad/frontend/lib/models/parsed_intent.dart)
- Keep all fields **non-nullable** but handle null JSON values via defaults in `fromJson`:
  - `locationText`: defaults to `'Not specified'`
  - `urgency`: defaults to `'flexible'`
  - `issueSummary`: defaults to `'Service request'`
  - `languageDetected`: defaults to `'unknown'`
- Add `fromJson()` and `toJson()` methods

#### [NEW] `lib/models/parse_response.dart`
Wraps full `/parse` response: `requestId`, `status`, `intent` (ParsedIntent), `missingFields`, `aiMessage`, `agentTrace`

#### [MODIFY] [provider.dart](file:///d:/juggaad/frontend/lib/models/provider.dart)  
- Keep `explanation` non-nullable with default `''`
- Add `fromJson()` and `toJson()` methods

#### [NEW] `lib/models/search_response.dart`
Wraps `/search` response: `requestId`, `providers`, `totalFound`, `top3Reasoning`, `agentTrace`

#### [NEW] `lib/models/book_response.dart`
Wraps `/book` response: `bookingId`, `trackingId`, `status`, `providerName`, `providerPhone`, `etaMinutes`, `confirmationText`, `simulated`, `agentTrace`

#### [NEW] `lib/models/booking_status.dart`
Wraps `GET /booking/{id}` response: `bookingId`, `trackingId`, `status`, `providerName`, `providerPhone`, `etaMinutes`, `lastUpdated`

#### [NEW] `lib/models/followup_response.dart`
Wraps `/followup` response: `message`, `sendAt`

#### [NEW] `lib/models/history_request_item.dart`
For `GET /history/requests`: `requestId`, `serviceType`, `locationText`, `urgency`, `issueSummary`, `createdAt`, `status`

#### [NEW] `lib/models/history_booking_item.dart`
For `GET /history/bookings`: `bookingId`, `requestId`, `providerId`, `providerName`, `providerPhone`, `serviceType`, `status`, `timeSlot`, `createdAt`

#### [NEW] `lib/models/user_profile.dart`
For profile endpoints: `uid`, `phoneNumber`, `displayName`, `createdAt`

---

#### [NEW] `lib/services/api_service.dart`
- Uses **Dio** with base URL `http://<backend-host>/api/v1`
- Dio interceptor: attaches `Authorization: Bearer <firebase_jwt>` header to every request
- Methods:
  - `parseRequest(String rawText, {String? languageHint, double? userLat, double? userLng})`
  - `searchProviders(SearchRequest request)`
  - `bookProvider(BookRequest request)`
  - `getBookingStatus(String bookingId)`
  - `sendFollowup(String bookingId, String trigger)`
  - `getHistoryRequests()`
  - `getHistoryBookings()`
  - `putProfile(String phoneNumber, {String? displayName})`
  - `getProfile()`

#### [NEW] `lib/services/firestore_service.dart`
- Uses **cloud_firestore** package
- Method: `Stream<List<AgentTrace>> streamAgentTrace(String requestId)` → listens to `service_requests/{requestId}` snapshots → extracts and returns the `agent_trace` array

#### [NEW] `lib/services/auth_service.dart`
- Uses **firebase_auth** + **google_sign_in** packages
- Methods: `signInWithGoogle()`, `signOut()`, `getCurrentUser()`, `getIdToken()`

#### [NEW] `lib/services/location_service.dart`
- Uses **geolocator** package
- Methods: `requestPermission()`, `getCurrentPosition()` → returns `(lat, lng)` tuple

---

#### [MODIFY] [chat_provider.dart](file:///d:/juggaad/frontend/lib/providers/chat_provider.dart)
- Keep existing `ChatNotifier` + `StateNotifier<List<ChatMessage>>`
- Add methods to interact with API service: `sendParseRequest()` that triggers the full flow

#### [NEW] `lib/providers/auth_provider.dart`
- `StreamProvider<User?>` wrapping Firebase Auth state
- `authServiceProvider` singleton

#### [NEW] `lib/providers/orchestration_provider.dart`
- `StateNotifier` managing the overall flow state:
  - `idle` → `parsing` → `parsedPreview` → `searching` → `providerResults` → `booking` → `confirmed` → `tracking`
- Stores current `requestId`, `parseResponse`, `searchResponse`, `bookResponse`

#### [NEW] `lib/providers/trace_stream_provider.dart`
- `StreamProvider.family<List<AgentTrace>, String>` that wraps `FirestoreService.streamAgentTrace(requestId)`
- Used by the Thinking/Trace UI component

#### [NEW] `lib/providers/history_provider.dart`
- `FutureProvider` for fetching request and booking history

#### [NEW] `lib/providers/profile_provider.dart`
- Manages user profile state (phone number, display name)

---

### Phase 1: Screen 1 — Login Screen
> Matches Stitch: **"Login - Teal & Amethyst"** + **"Login - Phone Number Prompt"**

#### [MODIFY] [login_screen.dart](file:///d:/juggaad/frontend/lib/screens/login_screen.dart)
- **Layout:** Centered column with Jugaad logo (bolt icon in rounded container with `secondaryContainer` background), brand title "Jugaad" in `headlineLg` primary color, tagline "Find trusted services near you" in `bodyMd`
- **Actions:** Single "Sign in with Google" button (white surface, border, Google icon) — calls real Firebase Google Sign-In
- **Remove:** "Continue as Guest" button
- **Phone Dialog:** After successful Google Sign-In, show a modal bottom sheet / dialog matching Stitch "Phone Number Prompt":
  - Purple icon circle (`tertiaryContainer` background)
  - "Complete your profile" heading
  - "Enter your phone number to continue" subtitle
  - Phone input with `+92` prefix, Pakistani placeholder `+92 300 1234567`
  - "Submit" button calls `PUT /api/v1/profile`
  - On success → navigate to Home

---

### Phase 2: Screen 2 — Home / AI Chat Interface
> Matches Stitch: **"Home - AI Chat Interface"**

#### [MODIFY] [home_screen.dart](file:///d:/juggaad/frontend/lib/screens/home_screen.dart)
- **Top Bar:** "Jugaad" title with bolt icon, user avatar on right
- **Service Category Pills:** Horizontal scrollable chips (Plumbing, Electrical, AC Repair, Carpentry, Cleaning) — labels only, tappable to pre-fill chat
- **Recent Requests Section:** Cards showing past requests from `GET /history/requests`
- **Bottom Input Bar:** Text field with microphone icon and send button
- **Chat Bubbles:** User messages on right, AI `ai_message` responses on left
- **Bottom Navigation Bar:** 3 tabs (Home, History, Profile) matching Stitch design
- **StreamBuilder Integration:** When a request is in-flight, an inline animated trace timeline shows agent thinking steps with `Future.delayed(500ms)` between each step

---

### Phase 3: Screen 3 — Parsed Request Preview
> Matches Stitch: **"Request Preview - Teal & Amethyst"**

#### [MODIFY] [parsed_request_screen.dart](file:///d:/juggaad/frontend/lib/screens/parsed_request_screen.dart)
- Displays extracted intent fields as editable chips/tags
- Confidence indicator bar
- "Edit" capability for each field
- "Find Providers" CTA button → triggers `POST /api/v1/search`

---

### Phase 4: Screen 4 — Provider Results
> Matches Stitch: **"Provider List - Updated Nav"**

#### [MODIFY] [provider_results_screen.dart](file:///d:/juggaad/frontend/lib/screens/provider_results_screen.dart)
- **Vertical list** of provider cards (NOT horizontal)
- Filter tabs at top (All, Nearby, Top Rated)
- Each card: provider name, rating stars, distance, ETA, base price, "Book" button
- AI reasoning explanation per provider
- Bottom Navigation Bar (3-tab)

---

### Phase 5: Screen 5 — Booking Confirmation
> Matches Stitch: **"Booking Confirmation - Teal & Amethyst"**

#### [MODIFY] [booking_confirmation_screen.dart](file:///d:/juggaad/frontend/lib/screens/booking_confirmation_screen.dart)
- Success checkmark animation
- Booking details: tracking ID, provider name, phone, ETA countdown
- "Track Provider" CTA → navigates to Tracking screen
- "Call Provider" action button

---

### Phase 6: Screen 6 — Tracking
> Matches Stitch: **"Tracking - Teal & Amethyst"**

#### [NEW] `lib/screens/tracking_screen.dart`
- Status timeline with steps (Confirmed → En Route → Arrived → Completed)
- Map placeholder showing direction from user location to provider location (using Pakistani coordinates from backend)
- Provider contact card
- ETA countdown
- "Send Follow-up" button → calls `POST /api/v1/followup`

---

### Phase 7: Screen 7 — Booking History
> Matches Stitch: **"Booking History - Cleaned"**

#### [NEW] `lib/screens/booking_history_screen.dart`
- Tab bar: "Requests" / "Bookings"
- List of history cards from `GET /api/v1/history/requests` and `GET /api/v1/history/bookings`
- Each card shows service type icon, status badge, date, provider name
- Bottom Navigation Bar (3-tab)

---

### Phase 8: Screen 8 — User Profile
> Matches Stitch: **"User Profile"**

#### [NEW] `lib/screens/user_profile_screen.dart`
- User avatar and display name from Firebase Auth
- Phone number from `GET /api/v1/profile`
- Settings/preferences section
- "Sign Out" button
- Bottom Navigation Bar (3-tab)

---

### Phase 9: Shell & Navigation

#### [MODIFY] [main.dart](file:///d:/juggaad/frontend/lib/main.dart)
- `ProviderScope` wrapping the app
- Route setup: Login → Home (with bottom nav shell: Home/History/Profile)
- Auth gate: redirect to Login if not authenticated

#### [NEW] `lib/screens/main_shell.dart`
- Scaffold with `BottomNavigationBar` (3 tabs: Home, History, Profile)
- `IndexedStack` or navigator for tab switching

---

### Phase 10: pubspec.yaml Dependencies

#### [MODIFY] [pubspec.yaml](file:///d:/juggaad/frontend/pubspec.yaml)
Add packages (per `docs/traces/` guidance):
- `flutter_riverpod` — state management
- `dio` — HTTP client
- `firebase_core`, `firebase_auth`, `cloud_firestore` — Firebase
- `google_sign_in` — Google Auth
- `geolocator` — device GPS
- `google_fonts` — Inter font family

---

## Execution Order

> [!IMPORTANT]
> Each phase is built **one at a time** with user review and consent before proceeding.

1. **Phase 0:** Foundation (theme, models, services, providers)
2. **Phase 1:** Login Screen + Phone Dialog
3. **Phase 2:** Home / Chat Screen
4. **Phase 3:** Parsed Request Preview
5. **Phase 4:** Provider Results
6. **Phase 5:** Booking Confirmation
7. **Phase 6:** Tracking
8. **Phase 7:** Booking History
9. **Phase 8:** User Profile
10. **Phase 9:** Shell & Navigation
11. **Phase 10:** pubspec.yaml finalization

---

## Verification Plan

### Per-Screen Verification
- After each screen: build the app (`flutter build apk --debug`) to verify no compile errors
- Visual comparison against the Stitch screenshot for that screen

### End-to-End Flow Test
- Google Auth → Phone Dialog → Chat input → Thinking animation → Parsed Preview → Provider List → Book → Confirmation → Tracking
- History tab shows past requests/bookings
- Profile tab shows user info and sign-out
