"""
Main API router.
Includes all sub-routers from the endpoints directory.
"""

from fastapi import APIRouter
from app.api.endpoints.search import router as search_router
from app.api.endpoints.book import router as book_router
from app.api.endpoints.followup import router as followup_router
from app.api.endpoints.history import router as history_router
from app.api.endpoints.profile import router as profile_router
from app.api.endpoints.chat import router as chat_router

api_router = APIRouter()


api_router.include_router(search_router, tags=["search"])
api_router.include_router(book_router, tags=["book"])
api_router.include_router(followup_router, tags=["followup"])
api_router.include_router(history_router, tags=["history"])
api_router.include_router(profile_router, tags=["profile"])
api_router.include_router(chat_router, tags=["chat"])
