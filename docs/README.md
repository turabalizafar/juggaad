# Trace Collection Plan — AISeekho Challenge 2

Do NOT fabricate traces. Capture real evidence during actual builds and demo runs.

---

## Folder Structure

```
docs/traces/
├── README.md                    ← this file
├── screenshots/
│   ├── 01_home_screen.png
│   ├── 02_parsed_request.png
│   ├── 03_provider_list.png
│   ├── 04_map_view.png
│   ├── 05_booking_confirmation.png
│   ├── 06_followup_message.png
│   └── 07_trace_log_view.png
├── recordings/
│   └── full_demo_run.mp4
├── api_logs/
│   ├── parse_request_sample.json
│   ├── provider_search_sample.json
│   ├── booking_create_sample.json
│   └── trace_export_sample.json
├── prompt_history/
│   ├── prompt1_intent_extraction_v1.txt
│   ├── prompt1_intent_extraction_v2.txt   ← if iterated
│   └── prompt2_explanation_v1.txt
└── gemini_artifacts/
    ├── raw_gemini_response_parse.json
    └── raw_gemini_response_explain.json
```

---

## Evidence Checklist

### Screenshots (capture these in order during demo)
- [ ] Home screen with input box
- [ ] Raw text entered by user
- [ ] Parsed request preview (service_type, urgency, location shown)
- [ ] Provider list with rankings and scores
- [ ] Map with provider pins visible
- [ ] Booking confirmation screen
- [ ] Follow-up reminder message shown in app
- [ ] GET /traces/{request_id} response shown (step log)

### Screen Recording
- [ ] Record full end-to-end flow: input → parse → providers → book → follow-up
- [ ] Keep under 3 minutes
- [ ] Narrate or add captions explaining each step
- [ ] Show the terminal / FastAPI logs in a split view if possible
- [ ] Save as `recordings/full_demo_run.mp4`

### API Logs
After each test run, copy the JSON request + response for:
- [ ] `POST /parse-request` (include raw Urdu/Roman Urdu input)
- [ ] `POST /providers/search` (include ranking scores)
- [ ] `POST /bookings/create`
- [ ] `GET /traces/{request_id}` (full step log)
Save to `api_logs/` as `.json` files.

### Prompt History
- [ ] Save exact prompt text used for Gemini (system + user template)
- [ ] Note the model name and max_tokens used
- [ ] If prompt was iterated, save each version with `_v1`, `_v2` suffix
- [ ] Save to `prompt_history/`

### Raw Gemini Artifacts
- [ ] Copy raw Gemini API response JSON (not just parsed output)
- [ ] Captures: model, usage.input_tokens, usage.output_tokens, content
- [ ] Save to `gemini_artifacts/`
- [ ] Evidence of actual AI calls made during the build

---

## Trace Service Requirements (Backend)

Every step in the pipeline must write to Firestore `traces` collection:

```json
{
  "id": "trace_auto_id",
  "request_id": "req_001",
  "step_name": "parse_request",
  "input_snapshot": { "raw_text": "...", "language_hint": "..." },
  "output_snapshot": { "service_type": "...", "urgency": "..." },
  "model_used": "gemini-1.5-flash",
  "tokens_used": 148,
  "timestamp": "2025-01-15T13:00:00Z",
  "duration_ms": 420
}
```

Steps to log:
1. `parse_request` — AI call
2. `geocode_location` — Maps API call
3. `provider_search` — filter + rank
4. `explanation_generated` — AI call
5. `booking_created` — DB write
6. `followup_generated` — AI call

---

## Token Usage Log

Track Gemini token usage per demo run. Export from raw API responses.

| Run # | Date | Flow | Input Tokens | Output Tokens | Total |
|-------|------|------|-------------|---------------|-------|
| 1     |      |      |             |               |       |
| 2     |      |      |             |               |       |

Target: under 500 tokens per full user flow.
