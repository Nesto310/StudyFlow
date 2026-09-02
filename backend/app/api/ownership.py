from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import AvailabilitySlot, Subject, Task


def owned_subject(
    db: Session, user_id: UUID, subject_id: UUID, *, lock: bool = False
) -> Subject:
    query = select(Subject).where(Subject.id == subject_id, Subject.user_id == user_id)
    if lock:
        query = query.with_for_update()
    subject = db.scalars(query).one_or_none()
    if subject is None:
        raise HTTPException(status_code=404, detail="Subject not found")
    return subject


def owned_task(db: Session, user_id: UUID, task_id: UUID) -> Task:
    task = db.scalars(
        select(Task).join(Subject).where(Task.id == task_id, Subject.user_id == user_id)
    ).one_or_none()
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


def owned_slot(db: Session, user_id: UUID, slot_id: UUID) -> AvailabilitySlot:
    slot = db.scalars(
        select(AvailabilitySlot).where(
            AvailabilitySlot.id == slot_id, AvailabilitySlot.user_id == user_id
        )
    ).one_or_none()
    if slot is None:
        raise HTTPException(status_code=404, detail="Availability slot not found")
    return slot
