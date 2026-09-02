from uuid import UUID

from fastapi import APIRouter, Response
from sqlalchemy import select

from app.api.dependencies import CurrentUser, DbSession
from app.api.ownership import owned_subject, owned_task
from app.api.transactions import commit_or_conflict
from app.models import Subject, Task
from app.schemas.task import TaskCreate, TaskRead, TaskUpdate

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.post("", response_model=TaskRead, status_code=201)
def create_task(payload: TaskCreate, db: DbSession, current_user: CurrentUser) -> Task:
    owned_subject(db, current_user.id, payload.subject_id)
    task = Task(**payload.model_dump(), is_completed=False)
    db.add(task)
    commit_or_conflict(db)
    db.refresh(task)
    return task


@router.get("", response_model=list[TaskRead])
def list_tasks(db: DbSession, current_user: CurrentUser):
    return db.scalars(
        select(Task).join(Subject).where(Subject.user_id == current_user.id)
        .order_by(Task.created_at, Task.id)
    ).all()


@router.get("/{task_id}", response_model=TaskRead)
def read_task(task_id: UUID, db: DbSession, current_user: CurrentUser) -> Task:
    return owned_task(db, current_user.id, task_id)


@router.patch("/{task_id}", response_model=TaskRead)
def update_task(
    task_id: UUID, payload: TaskUpdate, db: DbSession, current_user: CurrentUser
) -> Task:
    task = owned_task(db, current_user.id, task_id)
    updates = payload.model_dump(exclude_unset=True)
    if "subject_id" in updates:
        owned_subject(db, current_user.id, updates["subject_id"])
    for field, value in updates.items():
        setattr(task, field, value)
    commit_or_conflict(db)
    db.refresh(task)
    return task


@router.delete("/{task_id}", status_code=204)
def delete_task(task_id: UUID, db: DbSession, current_user: CurrentUser) -> Response:
    task = owned_task(db, current_user.id, task_id)
    db.delete(task)
    commit_or_conflict(db)
    return Response(status_code=204)
