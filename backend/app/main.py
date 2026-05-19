"""
FastAPI application entry point.
Initialises Firebase Admin, Vertex AI, Firestore, and Maps clients on startup.
Provides CORS middleware and a /health endpoint.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.schemas.common import HealthResponse, ErrorResponse
from app.services.gemini_client import GeminiClient
from app.services.firestore_client import FirestoreClient
from app.services.maps_client import MapsClient


# ── Global service instances (set during lifespan) ──────────────────────────
gemini_client: GeminiClient | None = None
firestore_client: FirestoreClient | None = None
maps_client: MapsClient | None = None

_services_status: dict[str, bool] = {
    "firestore": False,
    "gemini": False,
    "maps": False,
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: init all service clients. Shutdown: cleanup."""
    global gemini_client, firestore_client, maps_client, _services_status

    settings = get_settings()

    # ── Firebase Admin + Firestore ──────────────────────────────────────
    try:
        firestore_client = FirestoreClient()
        _services_status["firestore"] = True
        print("[OK] Firestore client initialised")
    except Exception as e:
        print(f"[WARN] Firestore init failed: {e}")

    # ── Vertex AI / Gemini ──────────────────────────────────────────────
    try:
        gemini_client = GeminiClient(
            project_id=settings.GCP_PROJECT_ID,
            region=settings.GCP_REGION,
        )
        _services_status["gemini"] = True
        print("[OK] Gemini (Vertex AI) client initialised")
    except Exception as e:
        print(f"[WARN] Gemini init failed: {e}")

    # ── Google Maps ─────────────────────────────────────────────────────
    try:
        maps_client = MapsClient(api_key=settings.MAPS_API_KEY)
        _services_status["maps"] = True
        print("[OK] Maps client initialised")
    except Exception as e:
        print(f"[WARN] Maps client init failed: {e}")

    print("\n[STARTUP COMPLETE]")
    yield  # app runs

    # Shutdown — nothing to clean up for now
    print("[SHUTDOWN]")


# ── App ─────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Juggaad — AI Service Orchestrator",
    description="AISeekho Challenge 2 backend",
    version="0.1.0",
    lifespan=lifespan,
)

# ── Routers ─────────────────────────────────────────────────────────────────
from app.api.router import api_router
app.include_router(api_router, prefix="/api/v1")

# ── CORS ────────────────────────────────────────────────────────────────────
# Re-read settings for CORS origins (safe — already validated in lifespan)
_settings = None
try:
    _settings = get_settings()
except SystemExit:
    pass  # will be caught properly during lifespan

_origins = (
    _settings.BACKEND_CORS_ORIGINS.split(",") if _settings else ["*"]
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health check ────────────────────────────────────────────────────────────
@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(status="ok", services=_services_status)
