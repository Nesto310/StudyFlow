from fastapi import APIRouter

from app.api.routes import health

api_router = APIRouter()
api_router.include_router(health.router)

# Domain endpoints will be grouped below this prefix in Phase 2B.
api_v1_router = APIRouter(prefix="/api/v1")
api_router.include_router(api_v1_router)
