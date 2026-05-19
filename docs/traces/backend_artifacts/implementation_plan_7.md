# Step 7: Flutter UI Implementation Plan

## Goal
Build the Juggaad mobile frontend in Flutter that connects seamlessly to our newly built FastAPI orchestrator. The app will feature a conversational, step-by-step UX with real-time UI updates (via Firestore) to simulate the AI's "Agentic Thinking".

## Proposed Architecture

- **State Management:** Riverpod (`flutter_riverpod`)
- **Networking:** Dio (with an interceptor to inject Firebase JWT tokens)
- **Database (Real-time):** `cloud_firestore` for the `StreamBuilder` that powers the thinking animation
- **Auth:** `firebase_auth`
- **Routing:** GoRouter (for clean declarative navigation)
- **Maps:** `google_maps_flutter`

## User Review Required
> [!IMPORTANT]
> The current plan focuses entirely on **hardcoding a test user's auth token** during local testing since you cannot run/compile the code locally. Does your teammate want to test with a real Firebase Login screen, or should I stub the login to auto-authenticate with a hardcoded JWT for the demo?

## Open Questions
> [!NOTE]  
> 1. Do you want me to write the code screen-by-screen so you can review each part, or write it all at once?
> 2. Should I set up the initial `pubspec.yaml` with all the required packages first?

## Proposed Changes (Module by Module)

### 1. Setup & Networking (`lib/core/`)
- **`pubspec.yaml`**: Add `dio`, `flutter_riverpod`, `firebase_core`, `cloud_firestore`, `firebase_auth`, `go_router`, `google_maps_flutter`.
- **`api_client.dart`**: Dio wrapper exposing `/parse`, `/search`, `/book`, `/followup`, `/history`.

### 2. State & Models (`lib/models/` & `lib/providers/`)
- Define Dart classes mirroring our Python schemas (`ParseResponse`, `Provider`, etc.).
- `service_flow_provider.dart`: A Riverpod `StateNotifier` that tracks the current `request_id`, the user's raw input, and the chosen provider throughout the flow.

### 3. Screens (`lib/screens/`)
#### [NEW] `home_screen.dart`
- A sleek text field for the user to type their request in Roman Urdu.
- Triggers `POST /parse` and navigates to the thinking screen.

#### [NEW] `thinking_screen.dart`
- Uses a `StreamBuilder` listening to `firestore.collection('service_requests').doc(requestId)`.
- Renders the `agent_trace` array in real-time, showing the AI's step-by-step logic.
- Auto-navigates when `status` changes to `complete`.

#### [NEW] `parse_preview_screen.dart`
- Shows the JSON intent extracted by Gemini.
- Allows user to edit missing fields (if `status == 'incomplete'`).
- "Confirm & Search" button calls `POST /search`.

#### [NEW] `provider_ranking_screen.dart`
- Shows Top 3 providers with their `rank_score`, `distance_km`, and Gemini's `explanation`.
- "Book" button calls `POST /book`.

#### [NEW] `booking_tracking_screen.dart`
- Shows the simulated booking confirmation.
- Integrates Google Maps SDK to show the user's location and provider's simulated ETA.
- Calls `POST /followup` to show reminder toasts.

## Verification Plan
1. I will write the `lib/main.dart` and the folder structure.
2. I will write the models and API client.
3. I will write the UI screens sequentially.
4. You will push to Git.
5. Your teammate will pull, run `flutter pub get`, and test against the running Python backend.
