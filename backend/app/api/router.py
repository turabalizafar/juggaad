"""
Main API router.
Includes all sub-routers from the endpoints directory.
"""

from fastapi import APIRouter
from app.api.endpoints.parse import router as parse_router
from app.api.endpoints.search import router as search_router
from app.api.endpoints.book import router as book_router
from app.api.endpoints.followup import router as followup_router
from app.api.endpoints.history import router as history_router

api_router = APIRouter()

api_router.include_router(parse_router, tags=["parse"])
api_router.include_router(search_router, tags=["search"])
api_router.include_router(book_router, tags=["book"])
api_router.include_router(followup_router, tags=["followup"])
api_router.include_router(history_router, tags=["history"])
