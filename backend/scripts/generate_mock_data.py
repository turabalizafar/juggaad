"""
Generate mock_providers.json with ~300 providers.
10 categories × 30 providers each.
18 cities in 3 geographic clusters.
All providers share one phone number for demo routing.
"""

import json
import random
import os

random.seed(42)  # reproducible

PHONE = "+923266142848"

# ── Geographic clusters ─────────────────────────────────────────────────────
CLUSTERS = {
    "A": {  # Punjab / GT Road
        "gujrat":       {"lat": 32.574, "lng": 74.075, "areas": ["City Center", "Jalalpur Jattan", "GT Road", "Bhimber Road"]},
        "wazirabad":    {"lat": 32.443, "lng": 74.120, "areas": ["City Center", "Kachhery Road", "Railway Road"]},
        "sialkot":      {"lat": 32.497, "lng": 74.531, "areas": ["Cantt", "Paris Road", "Kashmir Road", "Hajipura"]},
        "gujranwala":   {"lat": 32.162, "lng": 74.188, "areas": ["Satellite Town", "Model Town", "Civil Lines", "GT Road"]},
        "lalamusa":     {"lat": 32.704, "lng": 73.958, "areas": ["City Center", "GT Road", "Railway Colony"]},
        "jhelum":       {"lat": 32.934, "lng": 73.728, "areas": ["Cantt", "Civil Lines", "Sadar Bazaar", "GT Road"]},
        "lahore":       {"lat": 31.520, "lng": 74.358, "areas": ["DHA Phase 5", "Gulberg III", "Johar Town", "Model Town", "Bahria Town", "Garden Town"]},
        "sheikhupura":  {"lat": 31.713, "lng": 73.985, "areas": ["City Center", "Canal Road", "GT Road"]},
    },
    "B": {  # Capital / North
        "islamabad":    {"lat": 33.693, "lng": 73.064, "areas": ["F-6", "F-7", "F-10", "G-11", "G-13", "Blue Area", "I-8"]},
        "rawalpindi":   {"lat": 33.598, "lng": 73.048, "areas": ["Saddar", "Bahria Town", "Satellite Town", "Chaklala", "Commercial Market"]},
        "taxila":       {"lat": 33.745, "lng": 72.833, "areas": ["City Center", "Taxila Cantt", "Heavy Industries"]},
        "wah_cantt":    {"lat": 33.768, "lng": 72.751, "areas": ["Wah Cantt", "Lala Rukh", "POF Colony"]},
        "hasan_abdal":  {"lat": 33.810, "lng": 72.689, "areas": ["City Center", "GT Road", "Gurdwara Road"]},
        "murree":       {"lat": 33.908, "lng": 73.392, "areas": ["Mall Road", "GPO Chowk", "Jhika Gali", "Pindi Point"]},
    },
    "C": {  # South
        "karachi":      {"lat": 24.860, "lng": 67.010, "areas": ["Clifton", "DHA Phase 6", "PECHS", "Gulshan-e-Iqbal", "North Nazimabad", "Saddar"]},
        "hyderabad":    {"lat": 25.396, "lng": 68.377, "areas": ["Latifabad", "Qasimabad", "Auto Bhan Road", "City Center"]},
        "jamshoro":     {"lat": 25.430, "lng": 68.281, "areas": ["University Road", "City Center", "Indus Highway"]},
        "thatta":       {"lat": 24.747, "lng": 67.924, "areas": ["City Center", "Makli Road", "National Highway"]},
    },
}

# ── Service categories ──────────────────────────────────────────────────────
CATEGORIES = {
    "ac_technician": {
        "names": [
            "Usman AC Repair", "Cool Breeze Services", "Rana Cooling", "Ali AC Masters",
            "Quick Cool", "Ahmed Refrigeration", "Bilal AC Works", "Shahid Cooling Solutions",
            "Tariq AC Hub", "Nadeem Air Con", "Asif Cool Tech", "Imran AC Services",
            "Kamran Cooling", "Waqar AC Experts", "Faisal AC Fix", "Hassan Frost Services",
            "Zubair AC Care", "Salman Cool Works", "Rizwan AC Solutions", "Kashif Cooling Hub",
            "Danish AC Pro", "Omer Cool Fix", "Saad AC Works", "Junaid Cool Services",
            "Atif AC Repair", "Farhan Cool Masters", "Adeel AC Fix", "Hamza Cool Hub",
            "Irfan AC Works", "Sohail AC Services",
        ],
        "price_range": (500, 1500),
    },
    "plumber": {
        "names": [
            "Lahore Plumbing Hub", "Pipe Masters", "Ali Plumbing Services", "Quick Fix Plumbing",
            "Rana Water Works", "Ahmed Pipe Solutions", "Bilal Plumbing", "Shahid Sanitary Works",
            "Tariq Plumbing Hub", "Nadeem Water Services", "Asif Pipe Fix", "Imran Plumbing Pro",
            "Kamran Sanitary", "Waqar Plumbing Experts", "Faisal Pipe Masters", "Hassan Water Works",
            "Zubair Plumbing Care", "Salman Pipe Solutions", "Rizwan Plumbing Hub", "Kashif Water Fix",
            "Danish Plumbing Pro", "Omer Pipe Services", "Saad Plumbing Works", "Junaid Sanitary Hub",
            "Atif Plumbing Repair", "Farhan Water Masters", "Adeel Pipe Fix", "Hamza Plumbing Hub",
            "Irfan Plumbing Works", "Sohail Sanitary Services",
        ],
        "price_range": (400, 1200),
    },
    "electrician": {
        "names": [
            "Bright Sparks Electric", "Watt Solutions", "Ali Electric Services", "Quick Spark Fix",
            "Rana Electricals", "Ahmed Power Solutions", "Bilal Electric Works", "Shahid Wiring Hub",
            "Tariq Electric Pro", "Nadeem Power Fix", "Asif Electric Care", "Imran Wiring Services",
            "Kamran Electric Hub", "Waqar Power Experts", "Faisal Electric Fix", "Hassan Voltage Works",
            "Zubair Wiring Pro", "Salman Electric Solutions", "Rizwan Power Hub", "Kashif Electric Fix",
            "Danish Sparks Pro", "Omer Electric Services", "Saad Wiring Works", "Junaid Electric Hub",
            "Atif Power Repair", "Farhan Voltage Masters", "Adeel Electric Fix", "Hamza Sparks Hub",
            "Irfan Electric Works", "Sohail Power Services",
        ],
        "price_range": (400, 1200),
    },
    "cleaner": {
        "names": [
            "SparkleClean Services", "Neat & Tidy", "Ali Cleaning Hub", "Quick Shine Services",
            "Rana Deep Clean", "Ahmed Cleaning Pro", "Bilal Clean Works", "Shahid Cleaning Solutions",
            "Tariq Spotless Hub", "Nadeem Clean Fix", "Asif Shine Care", "Imran Cleaning Services",
            "Kamran Clean Pro", "Waqar Cleaning Experts", "Faisal SpotFree", "Hassan Clean Works",
            "Zubair Cleaning Care", "Salman Shine Solutions", "Rizwan Clean Hub", "Kashif SparkleClean",
            "Danish Clean Pro", "Omer Shine Services", "Saad Cleaning Works", "Junaid Clean Hub",
            "Atif Deep Clean", "Farhan Cleaning Masters", "Adeel Clean Fix", "Hamza Shine Hub",
            "Irfan Cleaning Works", "Sohail Clean Services",
        ],
        "price_range": (300, 1000),
    },
    "tutor": {
        "names": [
            "Khan Academy Tutors", "Learn Right Hub", "Ali Tutoring Services", "Quick Learn Pro",
            "Rana Education Hub", "Ahmed Teaching Solutions", "Bilal Tutors", "Shahid Learning Center",
            "Tariq Study Hub", "Nadeem Tutoring Pro", "Asif Learn Care", "Imran Teaching Services",
            "Kamran Study Pro", "Waqar Education Experts", "Faisal Learn Fix", "Hassan Knowledge Hub",
            "Zubair Teaching Care", "Salman Study Solutions", "Rizwan Learn Hub", "Kashif Tutoring Pro",
            "Danish Education Pro", "Omer Teaching Services", "Saad Study Works", "Junaid Learn Hub",
            "Atif Tutoring Repair", "Farhan Knowledge Masters", "Adeel Study Fix", "Hamza Learn Hub",
            "Irfan Teaching Works", "Sohail Education Services",
        ],
        "price_range": (300, 1000),
    },
    "beautician": {
        "names": [
            "Glow Beauty Studio", "Karachi Makeover", "Ali Beauty Services", "Quick Glow Salon",
            "Rana Beauty Hub", "Ahmed Grooming Pro", "Bilal Beauty Works", "Shahid Style Solutions",
            "Tariq Beauty Hub", "Nadeem Glow Pro", "Asif Style Care", "Imran Beauty Services",
            "Kamran Glow Pro", "Waqar Beauty Experts", "Faisal Style Fix", "Hassan Glamour Hub",
            "Zubair Beauty Care", "Salman Glow Solutions", "Rizwan Style Hub", "Kashif Beauty Pro",
            "Danish Glamour Pro", "Omer Beauty Services", "Saad Style Works", "Junaid Glow Hub",
            "Atif Beauty Studio", "Farhan Glamour Masters", "Adeel Style Fix", "Hamza Glow Hub",
            "Irfan Beauty Works", "Sohail Style Services",
        ],
        "price_range": (500, 2000),
    },
    "painter": {
        "names": [
            "Color Masters", "Fresh Coat Painters", "Ali Paint Services", "Quick Brush Fix",
            "Rana Paint Hub", "Ahmed Color Solutions", "Bilal Paint Works", "Shahid Brush Pro",
            "Tariq Paint Hub", "Nadeem Color Fix", "Asif Brush Care", "Imran Paint Services",
            "Kamran Color Pro", "Waqar Paint Experts", "Faisal Brush Fix", "Hassan Paint Works",
            "Zubair Color Care", "Salman Paint Solutions", "Rizwan Brush Hub", "Kashif Paint Pro",
            "Danish Color Pro", "Omer Paint Services", "Saad Brush Works", "Junaid Color Hub",
            "Atif Paint Repair", "Farhan Brush Masters", "Adeel Color Fix", "Hamza Paint Hub",
            "Irfan Brush Works", "Sohail Paint Services",
        ],
        "price_range": (600, 2000),
    },
    "carpenter": {
        "names": [
            "WoodCraft Services", "Furniture Fix Hub", "Ali Carpentry", "Quick Wood Fix",
            "Rana Wood Works", "Ahmed Furniture Solutions", "Bilal Carpentry Pro", "Shahid Wood Hub",
            "Tariq Furniture Fix", "Nadeem Wood Care", "Asif Carpentry Services", "Imran Wood Works",
            "Kamran Furniture Pro", "Waqar Carpentry Experts", "Faisal Wood Fix", "Hassan Furniture Hub",
            "Zubair Carpentry Care", "Salman Wood Solutions", "Rizwan Furniture Hub", "Kashif Wood Pro",
            "Danish Carpentry Pro", "Omer Wood Services", "Saad Furniture Works", "Junaid Wood Hub",
            "Atif Carpentry Repair", "Farhan Furniture Masters", "Adeel Wood Fix", "Hamza Furniture Hub",
            "Irfan Carpentry Works", "Sohail Wood Services",
        ],
        "price_range": (500, 2500),
    },
    "pest_control": {
        "names": [
            "BugFree Solutions", "Pest Shield Services", "Ali Pest Control", "Quick Bug Fix",
            "Rana Pest Hub", "Ahmed Fumigation Pro", "Bilal Pest Works", "Shahid Bug Solutions",
            "Tariq Pest Hub", "Nadeem Fumigation Fix", "Asif Bug Care", "Imran Pest Services",
            "Kamran Fumigation Pro", "Waqar Pest Experts", "Faisal Bug Fix", "Hassan Pest Works",
            "Zubair Fumigation Care", "Salman Pest Solutions", "Rizwan Bug Hub", "Kashif Pest Pro",
            "Danish Fumigation Pro", "Omer Pest Services", "Saad Bug Works", "Junaid Pest Hub",
            "Atif Fumigation Repair", "Farhan Pest Masters", "Adeel Bug Fix", "Hamza Pest Hub",
            "Irfan Fumigation Works", "Sohail Pest Services",
        ],
        "price_range": (800, 3000),
    },
    "shifting_service": {
        "names": [
            "SafeMove Packers", "Islamabad Movers", "Ali Shifting Services", "Quick Move Hub",
            "Rana Packers & Movers", "Ahmed Relocation Pro", "Bilal Shifting Works", "Shahid Move Solutions",
            "Tariq Packers Hub", "Nadeem Shifting Fix", "Asif Move Care", "Imran Relocation Services",
            "Kamran Packers Pro", "Waqar Shifting Experts", "Faisal Move Fix", "Hassan Relocation Hub",
            "Zubair Shifting Care", "Salman Move Solutions", "Rizwan Packers Hub", "Kashif Shifting Pro",
            "Danish Relocation Pro", "Omer Shifting Services", "Saad Packers Works", "Junaid Move Hub",
            "Atif Shifting Repair", "Farhan Relocation Masters", "Adeel Move Fix", "Hamza Packers Hub",
            "Irfan Shifting Works", "Sohail Relocation Services",
        ],
        "price_range": (3000, 8000),
    },
}

# ── Short codes ─────────────────────────────────────────────────────────────
CITY_CODES = {
    "gujrat": "gjt", "wazirabad": "wzb", "sialkot": "slk", "gujranwala": "gjw",
    "lalamusa": "llm", "jhelum": "jhm", "lahore": "lhr", "sheikhupura": "skp",
    "islamabad": "isb", "rawalpindi": "rwp", "taxila": "txl", "wah_cantt": "wah",
    "hasan_abdal": "hab", "murree": "mre",
    "karachi": "khi", "hyderabad": "hyd", "jamshoro": "jms", "thatta": "tht",
}

SERVICE_CODES = {
    "ac_technician": "ac", "plumber": "plm", "electrician": "elc",
    "cleaner": "cln", "tutor": "tut", "beautician": "bty",
    "painter": "pnt", "carpenter": "crp", "pest_control": "pst",
    "shifting_service": "shf",
}

def jitter(base: float, spread: float = 0.015) -> float:
    """Add small random offset to a coordinate for realistic spread."""
    return round(base + random.uniform(-spread, spread), 6)


def generate_providers() -> list[dict]:
    providers = []

    # Build flat city list with cluster info
    all_cities = []
    for cluster_id, cities in CLUSTERS.items():
        for city_name, info in cities.items():
            all_cities.append((cluster_id, city_name, info))

    for svc_type, svc_info in CATEGORIES.items():
        names = svc_info["names"]
        price_lo, price_hi = svc_info["price_range"]

        # Distribute 30 providers across 18 cities (round-robin with extras to larger cities)
        city_assignments = []
        for i in range(30):
            city_assignments.append(all_cities[i % len(all_cities)])

        for idx, (cluster_id, city_name, city_info) in enumerate(city_assignments):
            prov_num = idx + 1
            prov_id = f"prov_{CITY_CODES[city_name]}_{SERVICE_CODES[svc_type]}_{prov_num:03d}"

            area = random.choice(city_info["areas"])
            rating = round(random.uniform(3.5, 5.0), 1)
            # Better-rated providers tend to respond faster
            response_base = 45 - int((rating - 3.5) * 15)
            response_time = max(10, response_base + random.randint(-5, 10))

            # ~20% unavailable
            available = random.random() > 0.20

            providers.append({
                "id": prov_id,
                "name": names[idx],
                "phone_number": PHONE,
                "service_type": svc_type,
                "city": city_name,
                "area": area,
                "cluster": cluster_id,
                "rating": rating,
                "lat": jitter(city_info["lat"]),
                "lng": jitter(city_info["lng"]),
                "availability_status": available,
                "base_price": random.randrange(price_lo, price_hi + 1, 50),
                "response_time_minutes": response_time,
            })

    return providers


if __name__ == "__main__":
    providers = generate_providers()
    out_path = os.path.join(os.path.dirname(__file__), "..", "data", "mock_providers.json")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(providers, f, indent=2, ensure_ascii=False)

    # Summary
    from collections import Counter
    by_cat = Counter(p["service_type"] for p in providers)
    by_city = Counter(p["city"] for p in providers)
    by_cluster = Counter(p["cluster"] for p in providers)

    print(f"Generated {len(providers)} providers")
    print(f"\nBy category:")
    for cat, count in sorted(by_cat.items()):
        print(f"  {cat}: {count}")
    print(f"\nBy city:")
    for city, count in sorted(by_city.items()):
        print(f"  {city}: {count}")
    print(f"\nBy cluster:")
    for cl, count in sorted(by_cluster.items()):
        print(f"  Cluster {cl}: {count}")
    print(f"\nSaved to: {os.path.abspath(out_path)}")
