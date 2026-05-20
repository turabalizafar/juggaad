# Backend Alignment Fix — Task Tracker

- `[ ]` **1. New User Profile endpoint**
  - `[ ]` Create `app/schemas/user_profile.py`
  - `[ ]` Create `app/api/endpoints/profile.py` (PUT + GET)
  - `[ ]` Register in `app/api/router.py`
- `[ ]` **2. GPS location in /parse**
  - `[ ]` Add `user_lat`/`user_lng` to `ParseInput` schema
  - `[ ]` Update `parse.py` logic for GPS fallback
- `[ ]` **3. issue_summary deterministic fallback**
  - `[ ]` Add fallback in `parse.py`
- `[ ]` **4. Book auto-fill phone from profile**
  - `[ ]` Make `user_phone_number` optional in `BookRequest`
  - `[ ]` Update `book.py` to auto-fill from `users/{uid}`
- `[ ]` **5. Search lat/lng fallback**
  - `[ ]` Update `search.py` to read stored coords from service_requests doc
- `[ ]` **6. Update E2E test**
  - `[ ]` Add profile, GPS, and auto-fill test steps
- `[ ]` **7. Run E2E test and verify**
