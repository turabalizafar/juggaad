"""
Seed Firestore `providers` collection from mock_providers.json.
Clears existing providers first to avoid schema mismatch.

Usage:
    cd backend/
    python scripts/seed_db.py
"""

import json
import os
import sys

# Add parent dir so we can import app modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from dotenv import load_dotenv

# Load .env before any GCP imports
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

import firebase_admin
from firebase_admin import credentials, firestore


def get_firestore_client():
    """Initialise Firebase Admin and return Firestore client."""
    sa_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")
    if not sa_path or not os.path.isfile(sa_path):
        print(f"[FATAL] Service account file not found: {sa_path}")
        print("Set GOOGLE_APPLICATION_CREDENTIALS in .env to a valid path.")
        sys.exit(1)

    if not firebase_admin._apps:
        cred = credentials.Certificate(sa_path)
        firebase_admin.initialize_app(cred)

    return firestore.client()


def clear_collection(db, collection_name: str) -> int:
    """Delete all documents in a collection. Returns count deleted."""
    docs = db.collection(collection_name).stream()
    batch = db.batch()
    count = 0
    batch_count = 0

    for doc in docs:
        batch.delete(doc.reference)
        count += 1
        batch_count += 1

        # Firestore batch limit is 500
        if batch_count >= 500:
            batch.commit()
            batch = db.batch()
            batch_count = 0

    if batch_count > 0:
        batch.commit()

    return count


def seed_providers(db, providers: list[dict]) -> int:
    """Write providers to Firestore using provider id as doc ID."""
    count = 0
    for prov in providers:
        doc_id = prov["id"]
        db.collection("providers").document(doc_id).set(prov)
        count += 1

        if count % 25 == 0 or count == len(providers):
            print(f"  [{count}/{len(providers)}] Seeded {doc_id} ({prov['name']})")

    return count


def main():
    print("=" * 60)
    print("Juggaad — Firestore Provider Seeder")
    print("=" * 60)

    # Load mock data
    data_path = os.path.join(os.path.dirname(__file__), "..", "data", "mock_providers.json")
    if not os.path.isfile(data_path):
        print(f"[FATAL] Mock data file not found: {data_path}")
        print("Run 'python scripts/generate_mock_data.py' first.")
        sys.exit(1)

    with open(data_path, "r", encoding="utf-8") as f:
        providers = json.load(f)

    print(f"Loaded {len(providers)} providers from mock_providers.json")

    # Init Firestore
    db = get_firestore_client()
    print("[OK] Firestore connected")

    # Clear existing
    print("\nClearing existing providers collection...")
    cleared = clear_collection(db, "providers")
    print(f"Cleared {cleared} existing documents")

    # Seed
    print(f"\nSeeding {len(providers)} providers...")
    seeded = seed_providers(db, providers)

    # Summary
    from collections import Counter
    by_cat = Counter(p["service_type"] for p in providers)
    by_city = Counter(p["city"] for p in providers)
    by_cluster = Counter(p["cluster"] for p in providers)

    print("\n" + "=" * 60)
    print(f"DONE: Seeded {seeded} providers")
    print(f"\nBy category ({len(by_cat)} types):")
    for cat, cnt in sorted(by_cat.items()):
        print(f"  {cat}: {cnt}")
    print(f"\nBy city ({len(by_city)} cities):")
    for city, cnt in sorted(by_city.items()):
        print(f"  {city}: {cnt}")
    print(f"\nBy cluster:")
    for cl, cnt in sorted(by_cluster.items()):
        print(f"  Cluster {cl}: {cnt}")
    print("=" * 60)


if __name__ == "__main__":
    main()
