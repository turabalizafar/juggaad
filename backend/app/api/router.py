"""
Main API router.
Includes all sub-routers from the endpoints directory.
"""

from fastapi import APIRouter
from app.api.endpoints.parse import router as parse_router
from app.api.endpoints.search import router as search_router

api_router = APIRouter()

api_router.include_router(parse_router, tags=["parse"])
api_router.include_router(search_router, tags=["search"])
