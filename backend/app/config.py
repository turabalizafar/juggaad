"""
Application settings loaded from environment variables.
Uses pydantic-settings to validate and type-check all config.
Hard error on missing required keys — app refuses to start.
"""

import os
import sys
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """All configuration read from .env / environment variables."""

    # GCP / Vertex AI
    GCP_PROJECT_ID: str = ""
    GCP_REGION: str = "us-central1"
    GOOGLE_APPLICATION_CREDENTIALS: str = ""

    # Google Maps
    MAPS_API_KEY: str = ""

    # CORS
    BACKEND_CORS_ORIGINS: str = "http://localhost:3000"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


def get_settings() -> Settings:
    """Load settings and validate required keys are present."""
    settings = Settings()

    missing = []

    if not settings.GCP_PROJECT_ID:
        missing.append("GCP_PROJECT_ID")

    if not settings.GOOGLE_APPLICATION_CREDENTIALS:
        missing.append("GOOGLE_APPLICATION_CREDENTIALS")

    if not settings.MAPS_API_KEY:
        missing.append("MAPS_API_KEY")

    if missing:
        print(
            f"\n[FATAL] Missing required environment variables: {', '.join(missing)}\n"
            f"Create a .env file in the backend/ directory with these keys.\n"
            f"See .env.example for reference.\n"
        )
        sys.exit(1)

    # Verify service account file exists
    sa_path = settings.GOOGLE_APPLICATION_CREDENTIALS
    if not os.path.isfile(sa_path):
        print(
            f"\n[FATAL] Service account file not found: {sa_path}\n"
            f"Set GOOGLE_APPLICATION_CREDENTIALS to the correct path.\n"
        )
        sys.exit(1)

    # Set the env var so Firebase Admin and Vertex AI SDKs pick it up
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.path.abspath(sa_path)

    return settings
