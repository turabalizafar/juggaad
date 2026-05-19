You are building “Juggaad” — an AI service orchestrator for AISeekho Challenge 2.

SOURCE OF TRUTH: Read the docs folder first (architecture, api_design, prompts, tasks, decisions, UI plan).
Rules:
Ranking, distance, booking, and storage are deterministic.
Use real Firebase Auth verification.
Use real Google Maps Distance Matrix API for distance/ETA.
Support multiple service categories and multiple Pakistan cities.
If service not available or not recognized, return a clear “service_not_available” response and show a UI fallback.
No demo button; manual flow only.
Keep prompts short and focused.
KEY HANDLING RULES (strict):

Never place real API keys or secrets in source files.
Create .env.example with placeholders only (e.g., GOOGLE_MAPS_API_KEY=).
Read keys only from environment variables.
If a required key is missing, return a clear error response and stop the request.
If you need keys to continue, ask me explicitly and wait.
Implementation steps (do one step at a time, confirm before moving on):
Step 1: Backend skeleton in backend (FastAPI, CORS, health check, schemas, Gemini client, Firestore client, Firebase Auth verification).
Step 2: Mock provider dataset across multiple services and Pakistan cities; seed Firestore.
Step 3: /parse-request using Prompt 1 from docs/prompts.md; validate JSON; store request.
Step 4: /providers/search with deterministic ranking + Google Maps Distance Matrix; explanation via Prompt 2; handle service_not_available.
Step 5: /bookings/create, /bookings/{id}, /followups/reminder using Prompt 3;
Step 6: History endpoints for past requests and bookings (for “Call Again”).
Step 7: Flutter screens in order: Home → Parsed Preview → Provider List → Map → Booking → Tracking → History.
Step 8: Add loading and error states (service unavailable, no history, auth missing).
Step 9: Evidence checklist and trace capture plan (local files only).

Confirm after each step and do not add extra features.

Do not store traces in Firestore or any database.
If you need evidence artifacts, keep them local only and only when instructed.
Use Vertex AI for Gemini if the project already has GCP credits and setup.
Use a service account JSON file for local development, with a clear error if it is missing.
If a required key is missing, stop and ask for it rather than inventing a placeholder.
