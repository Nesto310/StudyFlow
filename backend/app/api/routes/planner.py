from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.api.dependencies import CurrentUser, DbSession
from app.models import AvailabilitySlot, Subject, Task
from app.schemas.planner import PlannerRequest, StudyPlan
from app.services.planner import generate_plan

router = APIRouter(prefix="/planner", tags=["planner"])


@router.post("/plan", response_model=StudyPlan)
def plan(payload: PlannerRequest, db: DbSession, current_user: CurrentUser) -> StudyPlan:
    tasks = db.scalars(
        select(Task).join(Subject).options(joinedload(Task.subject))
        .where(Subject.user_id == current_user.id, Task.is_completed.is_(False))
    ).all()
    slots = db.scalars(
        select(AvailabilitySlot).where(AvailabilitySlot.user_id == current_user.id)
    ).all()
    return generate_plan(tasks, slots, payload)
