from uuid import UUID

from fastapi import APIRouter, HTTPException, Response
from sqlalchemy import select

from app.api.dependencies import CurrentUser, DbSession
from app.api.ownership import owned_subject
from app.api.transactions import commit_or_conflict
from app.models import Subject, Task
from app.schemas.subject import SubjectCreate, SubjectRead, SubjectUpdate

router = APIRouter(prefix="/subjects", tags=["subjects"])


@router.post("", response_model=SubjectRead, status_code=201)
def create_subject(payload: SubjectCreate, db: DbSession, current_user: CurrentUser) -> Subject:
    subject = Subject(**payload.model_dump(), user_id=current_user.id)
    db.add(subject)
    commit_or_conflict(db)
    db.refresh(subject)
    return subject


@router.get("", response_model=list[SubjectRead])
def list_subjects(db: DbSession, current_user: CurrentUser):
    return db.scalars(
        select(Subject).where(Subject.user_id == current_user.id).order_by(Subject.created_at, Subject.id)
    ).all()


@router.get("/{subject_id}", response_model=SubjectRead)
def read_subject(subject_id: UUID, db: DbSession, current_user: CurrentUser) -> Subject:
    return owned_subject(db, current_user.id, subject_id)


@router.patch("/{subject_id}", response_model=SubjectRead)
def update_subject(
    subject_id: UUID, payload: SubjectUpdate, db: DbSession, current_user: CurrentUser
) -> Subject:
    subject = owned_subject(db, current_user.id, subject_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(subject, field, value)
    commit_or_conflict(db)
    db.refresh(subject)
    return subject


@router.delete("/{subject_id}", status_code=204)
def delete_subject(subject_id: UUID, db: DbSession, current_user: CurrentUser) -> Response:
    # PostgreSQL holds this row lock until commit, blocking concurrent FK inserts.
    subject = owned_subject(db, current_user.id, subject_id, lock=True)
    if db.scalar(select(Task.id).where(Task.subject_id == subject.id).limit(1)) is not None:
        raise HTTPException(status_code=409, detail="Subject has linked tasks")
    db.delete(subject)
    commit_or_conflict(db)
    return Response(status_code=204)
