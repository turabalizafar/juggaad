# Step 2: Mock Provider Dataset & Firestore Seeder — Plan

Text-only plan. **No code yet.** Waiting for approval before implementation.

---

## What Gets Built

### 1. `backend/data/mock_providers.json`

A single JSON file containing **~250 providers** (20–30 per category × 10 categories).

#### Service Categories (10)

| Category | Enum Value | Example Names |
|----------|-----------|---------------|
| AC Technician | `ac_technician` | Usman AC Repair, Cool Breeze Services |
| Plumber | `plumber` | Lahore Plumbing Hub, Karachi Pipe Masters |
| Electrician | `electrician` | Bright Sparks Electric, Watt Solutions |
| Cleaner | `cleaner` | SparkleClean Lahore, Neat & Tidy Services |
| Tutor | `tutor` | Khan Academy Tutors, Islamabad Learning |
| Beautician | `beautician` | Glow Beauty Studio, Karachi Makeover |
| Painter | `painter` | Color Masters, Fresh Coat Painters |
| Carpenter | `carpenter` | WoodCraft Services, Furniture Fix Lahore |
| Pest Control | `pest_control` | BugFree Solutions, Karachi Pest Shield |
| Shifting/Moving | `shifting_service` | SafeMove Packers, Islamabad Movers |

#### Cities & Sub-Areas (6 cities)

| City | Sub-Areas | Lat Range | Lng Range |
|------|-----------|-----------|-----------|
| **Lahore** | DHA, Gulberg, Johar Town, Model Town, Bahria Town | 31.40–31.58 | 74.20–74.42 |
| **Karachi** | Clifton, DHA, PECHS, Gulshan-e-Iqbal, North Nazimabad | 24.82–24.94 | 67.00–67.14 |
| **Islamabad** | F-6, F-7, F-10, G-11, G-13, Blue Area | 33.68–33.74 | 73.02–73.12 |
| **Rawalpindi** | Saddar, Bahria Town, Satellite Town | 33.56–33.62 | 73.04–73.10 |
| **Gujrat** | City Center, Jalalpur Jattan, GT Road area | 32.56–32.60 | 74.07–74.10 |
| **Faisalabad** | D Ground, Peoples Colony, Madina Town | 31.40–31.44 | 73.06–73.12 |

#### Provider JSON Schema (per object)

```json
{
  "id": "prov_lh_ac_001",
  "name": "Usman AC Repair",
  "phone_number": "+92-321-1234567",
  "service_type": "ac_technician",
  "city": "lahore",
  "area": "DHA Phase 5",
  "rating": 4.7,
  "lat": 31.4697,
  "lng": 74.4066,
  "availability_status": true,
  "base_price": 800,
  "response_time_minutes": 15
}
```

#### Data Distribution Rules

- **Per category**: 20–30 providers, distributed across at least 3 cities
- **Availability**: ~80% available, ~20% unavailable (4–6 per category)
- **Ratings**: Range 3.5–5.0, realistic bell curve (most 4.0–4.6)
- **Prices**: Vary by category (e.g., AC tech 500–1500, tutor 300–1000, shifting 3000–8000)
- **Response times**: 10–45 minutes, inversely correlated with rating (better providers respond faster)
- **Phone numbers**: Dummy +92-3xx-xxxxxxx format, unique per provider
- **IDs**: Pattern `prov_{city_code}_{service_code}_{number}` (e.g., `prov_lh_ac_001`, `prov_khi_plm_003`)

---

### 2. `backend/scripts/seed_db.py`

A standalone Python script that:

1. Loads `.env` from `backend/` directory
2. Initialises Firebase Admin using the service account
3. **Clears the existing `providers` collection** (deletes all documents)
4. Reads `backend/data/mock_providers.json`
5. Writes each provider as a document to Firestore `providers` collection using provider `id` as the document ID
6. Prints progress: `[1/250] Seeded prov_lh_ac_001 (Usman AC Repair)`
7. Prints summary: `Seeded 250 providers across 10 categories and 6 cities`

#### Clear Strategy

Before seeding, the script will:
- Fetch all documents in `providers` collection
- Delete them in batches of 500 (Firestore batch limit)
- Print `Cleared X existing providers`

This prevents schema mismatch if old data exists.

---

## What Does NOT Get Built

- No UI code
- No endpoint logic
- No trace storage
- No seed for `users`, `bookings`, or `service_requests` collections (those are created at runtime)

---

## Verification Plan

After implementation:
1. Run `python scripts/seed_db.py` — should print clear progress and summary
2. Spot-check Firestore console: verify documents exist with correct fields including `phone_number`
3. Run a quick query: `python -c "..."` to fetch one provider per category and print it
4. Verify ID format, phone format, coordinate ranges, and availability distribution
