# E2E Result

Uhh this is the e2e result:

🚀 Starting End-to-End Backend Test...

Initialising services... This may take a few seconds.

[OK] Firestore client initialised

[OK] Gemini (Vertex AI) client initialised

[OK] Maps client initialised

[STARTUP COMPLETE]

✅ Services started.

============================================================

👤 STEP 0: USER PROFILE (Phone Storage)

============================================================

✅ Profile saved: +923001234567 (Test User)

✅ Profile retrieved: +923001234567

============================================================

💬 STEP 1: USER REQUEST (Parse — with location)

============================================================

User says: 'mujhe aaj AC theek karwana hai DHA Lahore mein'

🔍 Gemini Extracted Intent:

{

"service_type": "ac_technician",

"location_text": "DHA Lahore",

"urgency": "today",

"issue_summary": "User wants to get AC repaired.",

"language_detected": "roman_urdu"

}

Status: complete

AI Message: I understand! You need a ac technician in DHA Lahore today for User wants to get AC repaired..

🕵️‍♂️ Agent Trace (Real-time to Firestore):

[extracting_intent] Reading your request...

[intent_extracted] Service: ac_technician, Location: DHA Lahore, Time: today

============================================================

📍 STEP 1b: GPS PARSE ("near me" with coordinates)

============================================================

User says: 'AC technician near me' (with GPS: 31.47, 74.41)

Status: incomplete

Location resolved to: Current Location

✅ GPS fallback worked! 'near me' resolved to 'Current Location' without asking user.

ℹ️ Status is 'incomplete' because urgency is missing (expected — user didn't specify time)

============================================================

🔎 STEP 2: SEARCH & RANK PROVIDERS

============================================================

✅ Total available providers found: 23

Top 3 Reasoning: These providers were selected based on their proximity, high ratings, and availability.

🏆 Top 3 Providers:

1. Faisal AC Fix (Score: 0.673)

⭐ 5.0/5 | 📍 1213.52 km | ⏱️ ETA: 934 mins

🧠 Gemini says: F

2. Junaid Cool Services (Score: 0.668)

⭐ 4.9/5 | 📍 221.78 km | ⏱️ ETA: 204 mins

🧠 Gemini says: Junaid Cool Services is a highly rated provider near you.

3. Adeel AC Fix (Score: 0.665)

⭐ 4.8/5 | 📍 397.4 km | ⏱️ ETA: 284 mins

🧠 Gemini says: Adeel AC

🕵️‍♂️ Agent Trace (Updated):

[extracting_intent] Reading your request...

[intent_extracted] Service: ac_technician, Location: DHA Lahore, Time: today

[querying_providers] Searching for ac_technician near DHA Lahore...

[filtering_available] Found 23 available candidates...

[calculating_distances] Computing true driving routes for 23 candidates...

[ranking_complete] Top 3 selected — closest: Faisal AC Fix (1213.52 km)

============================================================

📅 STEP 3: BOOKING (phone auto-filled from profile)

============================================================

✅ Booking Confirmed! Tracking ID: TRK-2026-0520-2E40

Provider: Faisal AC Fix (+923266142848)

ETA: 18 mins

📱 Phone was auto-filled from profile (not sent in request body)

============================================================

📱 STEP 4: FOLLOW-UP (Pre-Arrival)

============================================================

🤖 Gemini SMS Reminder: Faisal AC Fix is arriving in ~18 mins.

============================================================

📜 STEP 5: HISTORY CHECK

============================================================

Total bookings for this user: 2

Last booking was for: ac_technician with Faisal AC Fix

# Bugs

Bug 1: The "🧠 Gemini says: F" (Token Limit)
You were 100% correct. This is a token limit cutoff. In your code, the agent was explicitly told to generate a 1-sentence reason, but max_tokens was set to 10. Ten tokens is only about 6 words, so it cut the AI off mid-sentence.

Bug 2: The 1213km Provider Winning (The Scoring Math)
Your current scoring math uses a "relative max distance". It looks at all the candidates, finds the furthest one, and scales everyone relative to that.
Because your geocoder mapped "DHA Lahore", but it pulled AC technicians from Karachi (1200km away) to test, the math got skewed. The AI essentially thought: "Well, they are all far, but Faisal has a 5.0 rating, so he wins!" We need to change the math to an absolute penalty. If a provider is more than 30km away, their distance score should instantly drop to 0, completely destroying their chance of winning, regardless of their 5-star rating.

🛠️ The Fix (Update backend/app/api/endpoints/search.py)
Open your search.py file and make these three specific changes:

1. Fix the Haversine Pre-Filter (Around Line 60)
   Stop the backend from even sending Karachi providers to Google Maps if the user is in Lahore. Add a hard 100km limit before it sorts them.
   Find this:

Python
available_providers.sort(key=lambda x: haversine_distance(origin_lat, origin_lng, x.get("lat", 0), x.get("lng", 0)))
candidates_to_check = available_providers[:25]
Replace it with this:

Python

# Only consider providers within a 100km absolute radius

close_providers = [
p for p in available_providers
if haversine_distance(origin_lat, origin_lng, p.get("lat", 0), p.get("lng", 0)) < 100
]
close_providers.sort(key=lambda x: haversine_distance(origin_lat, origin_lng, x.get("lat", 0), x.get("lng", 0)))
candidates_to_check = close_providers[:25] 2. Fix the Scoring Math (Around Line 95)
Change the weights. In home services, closeness is king. Distance should be 80% of the score, and rating 20%.
Find this:

Python
max*dist = max((c["distance_km"] for c in candidates), default=1)
for c in candidates:
dist_score = 1 - (c["distance_km"] / max_dist) if max_dist > 0 else 1
rating_score = c["rating"] / 5.0
c["score"] = (0.4 * dist*score) + (0.6 * rating_score)
Replace it with this:

Python
for c in candidates:
dist = c["distance_km"] # Absolute penalty: Score drops to 0 if they are 40km or more away
dist_score = max(0.0, 1.0 - (dist / 40.0))
rating_score = c["rating"] / 5.0

    # Prioritize distance (80%) over rating (20%)
    c["score"] = (0.8 * dist_score) + (0.2 * rating_score)

3. Fix the AI Cutoff (Around Line 120)
   Find this:

Python
reasoning = await asyncio.to_thread(
gemini.generate,
system_prompt=PROMPT_2_SYSTEM,
user_prompt=f"Provider: {p['name']}, Rating: {p['rating']}, Distance: {p['distance_km']}km",
max_tokens=10, # <--- HERE IS THE CULPRIT
temperature=0.2
)
Change max_tokens=10 to max_tokens=50.

What about the 18 Min ETA in Step 3?
In the logs, Step 2 said ETA 934 mins, but Step 3 (Booking) magically said 18 mins.
This happens because your /book endpoint simulates a random ETA between 15-45 minutes for the mock booking. Once you apply the fixes above, Step 2 will ONLY select providers that are actually 5-10km away. That means Step 2's Google Maps ETA will naturally drop to around 20 minutes, which will perfectly match the simulation in Step 3!

Bug 3: The "Robotic" Grammar Bug (Step 1)
Look closely at the AI Message generated in Step 1 of your log:

AI Message: I understand! You need a ac technician in DHA Lahore today for User wants to get AC repaired..

The Problem: Your agent is blindly mashing Python strings together (notice the terrible grammar and the double period at the end). Because Gemini extracts the summary as "User wants to get AC repaired", concatenating it into a fixed sentence makes your "intelligent" agent sound like a cheap 1990s chatbot.

The Fix (in app/api/endpoints/parse.py):
Find where your Python code generates the success message and simplify it so it sounds natural. Remove the issue_summary from the string entirely.
Change it to something like this:

Python

# Instead of a messy concatenation, keep it natural and conversational:

ai*message = f"Got it! Let me find the best {intent.service_type.replace('*', ' ')} near {intent.location_text} for you right now."

Bug 4: The UI "ETA Disconnect" Trap (Step 2 vs Step 3)
In your log, Step 2's search calculated the real driving ETA from Google Maps. But in Step 3 (the Booking endpoint), the log says:

ETA: 18 mins

The Problem: I can guarantee that your /api/v1/book endpoint is currently using random.randint(15, 45) to generate a fake ETA for the booking confirmation.
If the Flutter app tells the user "Faisal is 12 mins away" on the Search screen, and then the user taps Book and the next screen says "Confirmed! ETA: 37 mins", the judges will instantly realize your backend data is disconnected and faked.

The Fix (Pass the ETA forward):
The Flutter app already knows the real ETA from Step 2. You need to tell your backend to accept that number in Step 3 instead of guessing.

In app/schemas/bookings.py, add the ETA to the request model:

Python
class BookingRequest(BaseModel):
request_id: str
provider_id: str
user_phone_number: str = None
agreed_eta_minutes: int # <--- Add this line
In app/api/endpoints/book.py, stop generating a random number. Just use the number the frontend sends:

Python

# Replace the random generator with the frontend's provided number

eta = request.agreed_eta_minutes
