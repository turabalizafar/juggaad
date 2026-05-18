AISeekho Hackathon Challenge 2 Master Brief
A detailed working guide for the Service Orchestrator build and CHAT LOGS

1. What this document is for
This document is a complete working brief for Challenge 2 of the AISeekho hackathon PLUS the chat logs with different aiagentss and their suggestions on the app. It is written so that another AI chat, Google AI Studio, a teammate’s laptop, or your own future self can open it and understand the entire project.
It combines: the challenge interpretation, the recommended architecture, the most practical tech stack, the AI workflow, the repo and team workflow, the credit and token-saving strategy, the Antigravity evidence trail, and a step-by-step implementation plan.
2. The core conclusion
Challenge 2 should be built as a service orchestration system, not as a simple booking app. The app should behave like an intelligent coordinator for informal service providers such as plumbers, electricians, AC technicians, tutors, beauticians, or cleaners.
The AI does not need to do everything by itself. The best architecture is a hybrid system:
•	Gemini / Vertex AI handles language understanding and explanation generation.
•	Deterministic backend logic handles provider filtering, distance calculations, ranking, bookings, and data storage.
•	Google Maps APIs handle geocoding, nearby search, route/distance logic, and ETA estimation.
•	Flutter handles the mobile experience.
•	FastAPI handles the orchestration layer and all API endpoints.
The project should demonstrate an end-to-end workflow: user request -> intent parsing -> provider search -> ranking -> booking simulation -> confirmation -> follow-up. That is the actual hackathon value.
3. What the product should feel like
The user should be able to type or speak a request in English, Urdu, or Roman Urdu. The system should identify the service type, the location, the urgency, and the service details. Then the system should show a ranked list of providers, explain why a provider was selected, simulate a booking, and show a confirmation plus a reminder or follow-up action.
A good demo is not just a pretty interface. It is a believable workflow with visible reasoning and state changes.
4. Recommended scope for a winning hackathon build
Do not try to build a giant marketplace for every service in the country. Pick one narrow but realistic demo lane and make that lane excellent.
•	Best option for speed: one hero category, such as AC technician or plumber.
•	Support more than one category in the backend if you can, but only demo one category well.
•	Use a mock provider dataset so the app always has enough results to rank.
•	Use Google Maps for visual credibility and a better demo experience.
•	Use Gemini for intent extraction and explanation only.
5. Suggested system architecture
A practical architecture for the project looks like this:
Flutter Mobile App
   ↓
FastAPI Backend (orchestrator)
   ├── Request Parsing Service (Gemini / Vertex AI)
   ├── Provider Matching Service (logic + Maps)
   ├── Booking Simulation Service
   ├── Follow-up / Notification Service
   ├── Logging / Trace Service
   └── Firestore / PostgreSQL database
This architecture is intentionally modular. The modular design makes the code easier to write, easier to debug, easier to demonstrate, and easier to explain in the final submission.
6. Recommended tech stack
The stack you suggested is strong and hackathon-friendly.
•	Frontend: Flutter
•	Backend: FastAPI
•	Database: Firestore for speed, or PostgreSQL if you already know it well
•	Auth: Firebase Auth
•	AI parsing and explanation: Vertex AI / Gemini API
•	Maps: Google Maps Platform
•	Hosting: Render, Cloud Run, or Firebase hosting depending on component
•	State management in Flutter: Riverpod or Bloc
•	HTTP client in Flutter: Dio
SOAP should not be used. REST APIs are the correct choice here because they are simple, standard, mobile-friendly, and much faster to build under time pressure.
7. Database recommendation
Use Firestore if speed matters most. It is easy to integrate with Flutter, it is flexible for a hackathon schema, and it supports rapid iteration. Use PostgreSQL only if your team is already more comfortable with relational models.
For this hackathon, Firestore is usually the safer choice.
•	users
•	providers
•	service_requests
•	bookings
•	events / traces
•	messages / chat history
8. Data model suggestion
Suggested collections or tables:
users
- id
- name
- phone
- preferred_language
- saved_locations

providers
- id
- name
- category
- rating
- latitude
- longitude
- availability_status
- base_price
- response_time_estimate

service_requests
- id
- user_id
- raw_input
- parsed_service_type
- parsed_location
- urgency
- status
- created_at

bookings
- id
- request_id
- provider_id
- time_slot
- booking_status
- simulated_confirmation_text

traces
- id
- request_id
- step_name
- input_snapshot
- output_snapshot
- timestamp
9. The AI workflow
The AI part should be structured as a small workflow, not as one giant prompt. This keeps costs down, improves reliability, and makes the project look more mature.
•	Request understanding: detect service type, urgency, location, and issue.
•	Provider search: filter candidate providers by category and region.
•	Ranking: rank providers using distance, rating, availability, and response time.
•	Explanation: generate a natural-language reason for the recommendation.
•	Booking simulation: create a mock confirmation and update the booking state.
•	Follow-up: generate reminders, ETA updates, and completion prompts.
Important principle: let AI do language and explanation. Let backend logic do calculations and decisions that can be computed deterministically.
10. Small agents explained in practical terms
The phrase 'small agents' does not mean you need a giant autonomous system. It usually means small specialized modules or services, each with one job.
•	Request Agent: converts user text into structured JSON.
•	Provider Agent: finds and ranks matching providers.
•	Booking Agent: simulates booking and confirmation.
•	Notification Agent: creates reminders and follow-up messages.
•	Trace Agent: stores the workflow steps and outputs for evidence.
These can be plain Python classes or FastAPI services. They do not need to be separate LLMs. The main idea is modularity.
11. REST API design
A good first version of your backend API could look like this:
POST /api/v1/parse-request
POST /api/v1/providers/search
POST /api/v1/bookings/create
GET  /api/v1/bookings/{booking_id}
GET  /api/v1/providers/nearby
GET  /api/v1/traces/{request_id}
POST /api/v1/followups/reminder
POST /api/v1/demo/run
Suggested endpoint roles:
•	/parse-request: calls Gemini and returns structured intent JSON.
•	/providers/search: returns ranked providers with reason scores.
•	/bookings/create: creates the simulated booking and confirmation.
•	/traces/{request_id}: returns the logged step-by-step workflow.
•	/demo/run: helpful for the hackathon demo flow when you want a single button action.
12. Flutter app screen plan
Your mobile app should have a small number of polished screens:
•	Login / welcome screen
•	Home screen with one large input box or voice input button
•	Parsed request preview screen
•	Provider ranking screen
•	Booking confirmation screen
•	Tracking / follow-up screen
•	History / saved bookings screen
Do not overbuild the UI. A clean, polished flow with one strong demo story is much more valuable than many unfinished screens.
13. How to integrate Google Maps
Google Maps is a major advantage because it gives the product immediate realism. Use maps where the user can see the provider location, approximate distance, and route preview.
•	Geocoding: convert location text into coordinates.
•	Nearby search: filter providers around the user.
•	Distance matrix: calculate distance and ETA.
•	Maps SDK: show providers on a map and make the app feel real.
Even if you keep the provider data mock, the Maps integration makes the system feel grounded in the real world.
14. Mock data strategy
Yes, use mock data. That is not a weakness; it is a smart hackathon move. Mock data is especially useful for providers, schedules, reviews, ratings, and booking slots.
•	Seed 20-50 providers with realistic names and service categories.
•	Include ratings, location coordinates, availability, and response times.
•	Include a few 'busy' and 'available' providers so ranking makes sense.
•	Make the data look varied enough for a good demo.
A strong hackathon project often mixes mock data with one or two real APIs. That gives you realism without build risk.
15. How to use AI without training a model
No, you should not train your own AI model for this hackathon. That would waste time and probably hurt your final product.
Use Gemini / Vertex AI to extract structured information from user text, then process that structure in your backend. That is exactly the right pattern for a 3-day or short hackathon build.
•	Use the model for intent extraction.
•	Use the model for reasoning explanations.
•	Use the model for summarization or follow-up text.
•	Do not use the model to replace all backend logic.
16. Credits and token usage problem
The community chat made it clear that many teams are hitting tool limits fast. The best solution is to use AI with discipline, not as an all-day brainstorming machine.
•	Plan outside Antigravity first.
•	Use a single architecture doc to preserve context.
•	Give Antigravity small, focused tasks.
•	Avoid giant prompts that mix architecture, UI, backend, and debugging all at once.
•	Use the AI where it directly saves coding time.
A very practical workflow is:
1. Plan in AI Studio / another chat
2. Save the plan into docs/architecture.md
3. Split the work into small tasks
4. Use Antigravity to implement one task at a time
5. Save the prompt used for each task in docs/prompts.md
6. Save screenshots and logs after each major milestone
17. What people meant by AI Studio planning
When people said to use AI Studio for planning features and migrations, they meant: use a cheaper or freer brainstorming environment to design the system first, and only then use Antigravity for execution.
•	Figure out the screens.
•	Figure out the API endpoints.
•	Figure out the database fields.
•	Figure out the prompt strategy.
•	Then move the final plan into Antigravity and code.
This saves tokens because the expensive tool is used mostly for implementation, not for endless concept exploration.
18. What MCP means in this context
MCP stands for Model Context Protocol. In simple terms, it gives the AI access to tools and services through a standard interface.
•	GitHub MCP can help interact with repositories, issues, or pull requests.
•	A filesystem MCP can let the agent inspect or update files.
•	A database MCP can let the agent inspect data or run safe queries.
•	An API MCP can expose a service to the agent in a controlled way.
For your hackathon, MCP is optional. Use it only if it clearly helps. Do not make your architecture dependent on MCP if it adds complexity.
19. GitHub repository setup for the team
Recommended repo workflow:
•	Create one private GitHub repo.
•	Add all teammates as collaborators.
•	Use a main branch plus feature branches.
•	Open pull requests for merges into main.
•	Keep the repo clean and readable.
Useful repo files:
README.md
docs/architecture.md
docs/api_design.md
docs/prompts.md
docs/tasks.md
docs/decisions.md
docs/traces/
lib/ or app/ source folders
.env.example
GitHub should be the team source of truth. Antigravity is the coding environment; GitHub is the shared record of what the team built.
20. Antigravity usage and evidence trail
Your earlier note about saving evidence is exactly right. Keep a visible trail while building.
•	Save plans.
•	Save task lists.
•	Save prompt iterations.
•	Save screenshots or screen recordings of Antigravity in action.
•	Export logs or artifact data from the IDE.
This is useful for two reasons: it helps the team stay organized, and it gives you proof of work for the submission.
21. A clean build order
1.	Step 1: agree on the exact Challenge 2 scope.
2.	Step 2: create the GitHub repo and collaboration rules.
3.	Step 3: create architecture.md and api_design.md.
4.	Step 4: seed mock provider data.
5.	Step 5: build the request parsing API.
6.	Step 6: build provider matching and ranking.
7.	Step 7: build booking simulation.
8.	Step 8: build follow-up/reminder logic.
9.	Step 9: build Flutter screens for the end-to-end flow.
10.	Step 10: connect maps and polish the demo.
11.	Step 11: save screenshots, prompts, logs, and demo recording.
12.	Step 12: prepare README and submission files.
22. Suggested project folder structure
project-root/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── agents/
│   │   ├── services/
│   │   ├── schemas/
│   │   ├── models/
│   │   ├── utils/
│   │   └── main.py
│   └── requirements.txt
├── mobile/
│   ├── lib/
│   └── pubspec.yaml
├── docs/
│   ├── architecture.md
│   ├── api_design.md
│   ├── prompts.md
│   ├── tasks.md
│   ├── decisions.md
│   └── traces/
└── README.md
23. Suggested implementation flow in code
The code should follow this sequence:
Flutter app sends user message
→ FastAPI /parse-request calls Gemini
→ response is normalized into JSON
→ provider search service filters providers
→ ranking service scores candidates
→ booking service creates simulated booking
→ follow-up service creates reminder/notification
→ trace service logs every step
→ Flutter shows final results
This is the clearest way to explain the system during judging, and it is also the easiest way to debug.
24. Important design principle: one source of truth
Do not let the frontend invent booking logic. Do not let the model invent provider data. Keep one authoritative backend data source and one authoritative workflow service.
•	Frontend displays state.
•	Backend owns business logic.
•	Database stores source-of-truth state.
•	AI only interprets and explains.
25. What to do before coding today
13.	Choose the exact service category for the demo.
14.	Create the repo.
15.	Write architecture.md.
16.	Write api_design.md.
17.	Write tasks.md with the first 5 tasks only.
18.	Seed mock provider data.
19.	Create one prompt for request parsing.
20.	Create one prompt for explanation generation.
21.	Do not start by building every screen.
26. Common mistakes to avoid
•	Trying to train a custom model.
•	Trying to support too many services in the first version.
•	Letting AI do pure database logic.
•	Overbuilding authentication and payments.
•	Using vague mega-prompts and wasting tokens.
•	Skipping logs and evidence.
•	Skipping the demo script.
•	Building UI before the backend flow is clear.
27. Suggested prompts to reuse with other AIs
Prompt for architecture design:
Design a Flutter + FastAPI + Gemini service orchestration system for Challenge 2 of the AISeekho hackathon.
The system should parse user requests in Urdu, Roman Urdu, and English, find nearby providers using mock data and Google Maps APIs, rank them by distance/rating/availability, simulate booking, and generate follow-up reminders.
Return:
1. architecture diagram
2. database schema
3. API endpoints
4. module breakdown
5. implementation milestones
Prompt for backend generation:
Generate a FastAPI backend for a service-orchestration app.
Requirements:
- REST endpoints only
- Pydantic schemas
- Gemini request parsing
- provider ranking logic
- booking simulation
- trace logging
- clean modular structure
- support for Firestore or PostgreSQL
Return production-ready code in separate files with comments.
Prompt for Flutter generation:
Generate Flutter screens for a service orchestrator app:
- home input screen
- parsed request preview
- provider list with ranking
- booking confirmation
- status tracking
Use Riverpod or Bloc, Dio for networking, and clean UI components.
28. Final recommendation
Your strongest plan is this: Flutter + FastAPI + Firestore + Gemini + Google Maps + mock providers + a clean trace trail. That is enough to build a compelling, judges-friendly hackathon product in a short time.
The winning strategy is not maximum complexity. It is maximum clarity, end-to-end completeness, and strong evidence of agentic workflow.
29. Copy-paste summary for another AI chat
We are building AISeekho Challenge 2: an AI service orchestrator for informal service providers. The stack is Flutter mobile app + FastAPI backend + Firestore + Gemini/Vertex AI + Google Maps APIs. The app must parse user requests in Urdu/Roman Urdu/English, identify service type/location/urgency, find mock providers near the user, rank them using distance/rating/availability, simulate booking, and generate follow-up reminders. Use small modular agents/services rather than one giant AI call. Keep architecture.md, api_design.md, prompts.md, tasks.md, and trace logs in the repo. Use REST APIs, not SOAP. Use mock data to avoid delays. Use AI for intent parsing and explanation, and use backend logic for ranking and bookings. The main goal is a polished end-to-end demo with visible reasoning, logs, and before/after state changes.

Prepared as a reusable working brief for development and handoff.

Project Understanding
End-to-end goal: build a believable service-orchestration demo where a user types a request (English/Urdu/Roman Urdu), the system extracts intent, finds nearby providers, ranks them deterministically, simulates a booking, and shows a follow‑up message with traceable steps.

Safest 3‑day MVP scope:

One hero category (AC technician), one city area (DHA Lahore), mock provider dataset.
One full user flow only: request → parse → ranked list → booking → follow‑up.
Minimal auth (guest or test user), Maps for visual credibility, and short AI prompts.
Biggest risks and how to contain them:

Token usage: keep prompts small, only 2–3 calls per flow; avoid multi‑step chatty prompts.
Implementation complexity: avoid real-time tracking, payments, onboarding, or admin panels.
Time risks: build backend flow first, then UI; lock scope to a single demo lane.
Scope creep: freeze categories, screens, and endpoints early; say “no” to stretch features.
AI hallucinations: never let AI produce business logic or data; validate AI JSON strictly.
AI‑driven vs deterministic:

AI: intent extraction, top‑provider explanation, short follow‑up message.
Deterministic: filtering, ranking math, distance calculations, booking state, storage, and all API responses.
Recommended System Design
Flutter mobile app:

Screens: 6–7 core screens only.
State: Riverpod; HTTP: Dio; Maps: google_maps_flutter.
Focus on the demo flow rather than full UX.
FastAPI backend:

Modular services: parse, provider search + rank, booking, follow‑up, traces.
Strict Pydantic validation; one trace log per step.
REST endpoints only, with predictable JSON shapes.
AI layer:

Gemini 1.5 Flash for intent, explanation, follow‑up.
Keep prompts short; enforce JSON only for intent extraction.
Do not call AI inside ranking or booking logic.
Database/storage:

Firestore for speed and easy Flutter integration.
Collections: users, providers, service_requests, bookings, traces.
Google Maps:

Geocoding and Distance Matrix for realistic distances and ETA.
Maps SDK in Flutter for pins and credibility.
Authentication:

For MVP, use guest/test user; real Firebase Auth as stretch.
If used, pass Firebase JWT to backend.
Logging/traces:

Trace each step (parse, search, booking, follow‑up).
Store input + output snapshots for evidence.
Notifications:

Simulated in-app follow‑up messages; no push notifications for MVP.
Mock vs real data:

Use mock provider data for reliability; optionally use Maps for distance realism.
Hybrid is ideal: mock providers + real Maps distance/ETA.
Role of Gemini/Vertex AI:

Extract structured intent, explain the top recommendation, generate reminder text.
It should never decide ranking, distance, availability, or booking outcomes.
Data Flow (Step-by-Step)

User input (text) → send to /parse-request.
AI returns structured JSON: service_type, location_text, urgency, issue_summary.
Backend saves request; logs parse_request.
User location → /providers/search with service_type + lat/lng.
Backend filters providers, calls Distance Matrix, ranks deterministically.
AI writes one‑sentence explanation for top provider.
Backend logs provider_search and returns ranked list.
User selects provider → /bookings/create.
Backend creates simulated booking; logs booking_created.
App requests follow‑up → /followups/reminder.
Backend returns short reminder message; logs followup_generated.
Key request/response shapes (MVP):

parse-request: raw_text + language_hint → intent JSON
providers/search: service_type + user lat/lng → ranked list + explanation
bookings/create: request_id + provider_id → booking confirmation
followups/reminder: booking_id + trigger → reminder message
traces/{request_id}: ordered step log
Docs Already Done
Your docs already cover architecture, API design, prompts, tasks, decisions, and UI map. I will not regenerate them unless you want revisions. I can review and refine any of them on request.

Trace Collection Plan (No Fabricated Traces)
Plan for docs/traces/ or docs/logs/

Folder structure:
traces/api_logs/
traces/screenshots/
traces/screen_recordings/
traces/prompt_history/
traces/notes/
Checklist:
Capture one successful end‑to‑end flow
Save prompt inputs/outputs for AI calls
Export Firestore trace records
Screenshot each core screen
Record a full demo run (60–90 seconds)
Note any failures + fixes in a short log
Stitch UI Planning (Screen Map)

Login / Welcome
Purpose: entry, optional auth.
Layout: centered card, logo, buttons.
Components: logo, app name, tagline, “Sign in with Google”, “Continue as Guest”.
Action: enter app.
Data: auth response or guest user.
Home (Request Input)
Purpose: collect user request.
Layout: large input field, primary CTA.
Components: greeting, multiline input, “Find Providers”, “Run Demo”.
Action: POST parse‑request.
Data: none yet.
Parsed Request Preview
Purpose: confirm AI understanding.
Layout: summary card + confirm CTA.
Components: service type chip, location, urgency, issue summary, edit button.
Action: confirm → providers/search; edit → back.
Data: parse‑request response.
Provider Ranking List
Purpose: show ranked providers.
Layout: list cards + explanation text.
Components: provider name, rating, distance, ETA, price, availability, book button.
Action: select provider → booking/create.
Data: providers/search response.
Map View
Purpose: visual credibility.
Layout: map with pins, back button.
Components: map, provider pins, selection highlight.
Action: return to list or choose provider.
Data: providers/search response or /providers/nearby.
Booking Confirmation
Purpose: confirm booking.
Layout: success state + details card.
Components: status icon, provider info, ETA, booking ID, “Track Provider”.
Action: go to tracking.
Data: bookings/create response.
Tracking / Follow‑up
Purpose: simulate progress and show reminder.
Layout: status timeline, mini map, reminder card.
Components: status steps, ETA, reminder text, rate button.
Action: view, optionally rate.
Data: bookings/{id} + followups/reminder.
Master Antigravity Prompt
Use this as a single prompt to kick off implementation, with strict steps and low token usage:

You are building “Juggaad” — an AI service orchestrator for AISeekho Challenge 2.
SOURCE OF TRUTH: read the docs folder first (architecture, api_design, prompts, tasks, decisions, UI map).
Rules:

Do not build monolithic code.
AI is only for intent extraction, explanation, follow‑up.
Ranking, distance, booking, and storage are deterministic.
Strictly follow JSON schemas from api_design.
Log every step to traces.
Keep prompts small and focused.
Implement in steps:
Step 1: Backend skeleton (FastAPI app, CORS, health check, schemas, Gemini client, Firestore client).
Step 2: Mock provider data + seeding script.
Step 3: /parse-request endpoint with Gemini Prompt 1, validate JSON, log trace.
Step 4: /providers/search with deterministic ranking, Maps distance, explanation with Prompt 2, log trace.
Step 5: /bookings/create, /bookings/{id}, /followups/reminder with Prompt 3, /traces/{request_id}, /demo/run.
Step 6: Flutter screens in order (Home → Parsed → Provider List → Map → Booking → Tracking).
Step 7: Loading/error states + demo polish + evidence checklist.

Work step‑by‑step, confirm after each step, avoid extra features.

Ignore hero ctaegories mock dataset would include multiple services and if the users' need is not in it then a simple "Service not available message should appear" also multiple city areas of pakistan..

Real FireBAse Auth
real google maps distance matrix
manual: remove run demo button
Me

Also add another screen history to show previous services and option to call them again

Now keeping these in mind give me the stitch prompts again (ifthey are changed but if not, then don't type them again) also tell me thesteps to implement now and the master prompt for antigravity

Got it. Here are the updated Stitch prompts (only the ones that changed) plus the new implementation steps and the revised master Antigravity prompt.

**Updated Stitch Prompts (Changed Only)**  
1) Home (Request Input)  
- Change: remove “Run Demo” button.  
- Add: subtle hint that multiple services/cities are supported.  
- Action: POST `/parse-request` only.

2) Parsed Request Preview  
- Change: add explicit “Service not available” fallback state if `service_type` is not supported or provider search returns zero.

3) Provider Ranking List  
- Change: handle multiple service categories; add “Service not available” empty state with back button.

4) History Screen (New)  
- Purpose: list past service requests and bookings.  
- Layout: timeline list with provider name, service type, date, status.  
- Components: list items with “Call Again” CTA, filter chips by service type and city.  
- Action: tap item to view details or “Call Again” to re-run search.  
- Data: from `bookings` + `service_requests` history endpoints.

---

**Implementation Steps (Updated)**  
1) Backend skeleton with real Firebase Auth verification middleware.  
2) Mock provider dataset expanded across multiple services + multiple Pakistan cities.  
3) `/parse-request` with Gemini Prompt 1, validate JSON, store request.  
4) `/providers/search` with real Google Maps Distance Matrix, deterministic ranking; if zero results → return “service_not_available” response.  
5) `/bookings/create`, `/bookings/{id}`, `/followups/reminder`, `/traces/{request_id}`.  
6) Add history endpoints: `/history/requests` and `/history/bookings` (filtered by user).  
7) Flutter screens (Home → Parsed Preview → Provider List → Map → Booking → Tracking → History).  
8) Empty states: service not available, no history yet, auth required.  
9) Evidence capture and trace export.

---

**Master Antigravity Prompt (Revised)**  
You are building “Juggaad” — an AI service orchestrator for AISeekho Challenge 2.

SOURCE OF TRUTH: read the docs folder first (architecture, api_design, prompts, tasks, decisions, UI map).  
Rules:  
1) AI is only for intent extraction, explanation, follow‑up.  
2) Ranking, distance, booking, and storage are deterministic.  
3) Use real Firebase Auth verification.  
4) Use real Google Maps Distance Matrix API for distance/ETA.  
5) Support multiple service categories and multiple Pakistan city areas.  
6) If service not available, return a clear “service_not_available” response and UI state.  
7) No demo button; manual flow only.  
8) Log every step to traces.  
9) Keep prompts short and focused.

Steps:  
Step 1: Backend skeleton (FastAPI, CORS, health check, schemas, Gemini client, Firestore client, Firebase Auth verification).  
Step 2: Mock provider dataset with multiple services + multiple Pakistan cities; seed Firestore.  
Step 3: `/parse-request` with Gemini Prompt 1; validate JSON; store request; trace `parse_request`.  
Step 4: `/providers/search` with deterministic ranking + real Maps Distance Matrix; explanation with Prompt 2; trace `provider_search`; handle no results.  
Step 5: `/bookings/create`, `/bookings/{id}`, `/followups/reminder` with Prompt 3, `/traces/{request_id}`.  
Step 6: Add history endpoints for user requests and bookings.  
Step 7: Flutter screens in order: Home → Parsed Preview → Provider List → Map → Booking Confirm → Tracking → History.  
Step 8: Add empty/error states (service not available, no history, auth missing).  
Step 9: Evidence capture and trace export checklist.

Confirm after each step, avoid extra features, and keep token usage low.

If you want me to update the docs for these changes or revise the prompts in docs/prompts.md, say the word.