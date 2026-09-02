from uuid import UUID

from fastapi import APIRouter, HTTPException, Response
from sqlalchemy import select

from app.api.dependencies import CurrentUser, DbSession
from app.api.ownership import owned_slot
from app.api.transactions import commit_or_conflict
from app.models import AvailabilitySlot
from app.schemas.availability import AvailabilityCreate, AvailabilityRead, AvailabilityUpdate

router = APIRouter(prefix="/availability", tags=["availability"])


@router.post("", response_model=AvailabilityRead, status_code=201)
def create_slot(
    payload: AvailabilityCreate, db: DbSession, current_user: CurrentUser
) -> AvailabilitySlot:
    slot = AvailabilitySlot(**payload.model_dump(), user_id=current_user.id)
    db.add(slot)
    commit_or_conflict(db)
    db.refresh(slot)
    return slot


@router.get("", response_model=list[AvailabilityRead])
def list_slots(db: DbSession, current_user: CurrentUser):
    return db.scalars(
        select(AvailabilitySlot).where(AvailabilitySlot.user_id == current_user.id)
        .order_by(AvailabilitySlot.day_of_week, AvailabilitySlot.start_time, AvailabilitySlot.id)
    ).all()


@router.get("/{slot_id}", response_model=AvailabilityRead)
def read_slot(slot_id: UUID, db: DbSession, current_user: CurrentUser) -> AvailabilitySlot:
    return owned_slot(db, current_user.id, slot_id)


@router.patch("/{slot_id}", response_model=AvailabilityRead)
def update_slot(
    slot_id: UUID, payload: AvailabilityUpdate, db: DbSession, current_user: CurrentUser
) -> AvailabilitySlot:
    slot = owned_slot(db, current_user.id, slot_id)
    updates = payload.model_dump(exclude_unset=True)
    start_time = updates.get("start_time", slot.start_time)
    end_time = updates.get("end_time", slot.end_time)
    if start_time >= end_time:
        raise HTTPException(status_code=422, detail="start_time must be earlier than end_time")
    for field, value in updates.items():
        setattr(slot, field, value)
    commit_or_conflict(db)
    db.refresh(slot)
    return slot


@router.delete("/{slot_id}", status_code=204)
def delete_slot(slot_id: UUID, db: DbSession, current_user: CurrentUser) -> Response:
    slot = owned_slot(db, current_user.id, slot_id)
    db.delete(slot)
    commit_or_conflict(db)
    return Response(status_code=204)
