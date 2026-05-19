"""
Firestore client wrapper.
Uses the Firebase Admin SDK (already authenticated via GOOGLE_APPLICATION_CREDENTIALS).
Provides CRUD helpers + agent trace appending for real-time Flutter streaming.
"""

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.base_query import FieldFilter


class FirestoreClient:
    """Thin wrapper around Firestore for the Juggaad backend."""

    def __init__(self) -> None:
        """
        Initialise Firebase Admin app and Firestore client.
        Uses GOOGLE_APPLICATION_CREDENTIALS env var (set by config.py).

        If Firebase Admin is already initialised, reuses the existing app.
        """
        if not firebase_admin._apps:
            cred = credentials.ApplicationDefault()
            firebase_admin.initialize_app(cred)

        self._db = firestore.client()

    @property
    def db(self):
        """Direct access to the Firestore client for advanced queries."""
        return self._db

    # ── CRUD helpers ────────────────────────────────────────────────────

    def add_document(self, collection: str, data: dict, doc_id: str | None = None) -> str:
        """
        Add a document to a collection.

        Args:
            collection: Firestore collection name.
            data: Document data dict.
            doc_id: Optional explicit document ID. Auto-generated if None.

        Returns:
            str: The document ID.
        """
        if doc_id:
            self._db.collection(collection).document(doc_id).set(data)
            return doc_id
        else:
            _, doc_ref = self._db.collection(collection).add(data)
            return doc_ref.id

    def get_document(self, collection: str, doc_id: str) -> dict | None:
        """
        Get a single document by ID.

        Returns:
            dict with document data, or None if not found.
        """
        doc = self._db.collection(collection).document(doc_id).get()
        if doc.exists:
            return {"id": doc.id, **doc.to_dict()}
        return None

    def get_documents(self, collection: str, limit: int = 100) -> list[dict]:
        """
        Get all documents in a collection (with limit).

        Returns:
            list[dict]: List of document dicts with 'id' field included.
        """
        docs = self._db.collection(collection).limit(limit).stream()
        return [{"id": doc.id, **doc.to_dict()} for doc in docs]

    def query_collection(
        self, collection: str, field: str, op: str, value, limit: int = 100
    ) -> list[dict]:
        """
        Query a collection with a single filter.

        Args:
            collection: Collection name.
            field: Field name to filter on.
            op: Operator string (e.g. '==', '>=', 'in').
            value: Value to compare against.
            limit: Max results.

        Returns:
            list[dict]: Matching documents.
        """
        query = (
            self._db.collection(collection)
            .where(filter=FieldFilter(field, op, value))
            .limit(limit)
        )
        docs = query.stream()
        return [{"id": doc.id, **doc.to_dict()} for doc in docs]

    def update_document(self, collection: str, doc_id: str, data: dict) -> None:
        """Update fields on an existing document."""
        self._db.collection(collection).document(doc_id).update(data)

    # ── Agent Trace Logging ─────────────────────────────────────────────

    def append_trace(self, request_id: str, step: str, message: str, timestamp: str) -> None:
        """
        Append a trace step to the service_requests/{request_id} document.

        Uses Firestore arrayUnion so the Flutter app can stream updates
        in real-time via a snapshot listener on the document.

        Args:
            request_id: The service request document ID.
            step: Short step identifier (e.g. 'extracting_intent').
            message: Human-readable description of what happened.
            timestamp: ISO 8601 timestamp string.
        """
        trace_entry = {
            "step": step,
            "message": message,
            "timestamp": timestamp,
        }
        self._db.collection("service_requests").document(request_id).update(
            {"agent_trace": firestore.ArrayUnion([trace_entry])}
        )
