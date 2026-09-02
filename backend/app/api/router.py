from fastapi import APIRouter

from app.api.routes import auth, availability, health, subjects, tasks, users

api_router = APIRouter()
api_router.include_router(health.router)

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(auth.router)
api_v1_router.include_router(users.router)
api_v1_router.include_router(subjects.router)
api_v1_router.include_router(tasks.router)
api_v1_router.include_router(availability.router)
api_router.include_router(api_v1_router)
