from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from pydantic import AfterValidator, AwareDatetime, Field, StrictBool, StringConstraints, field_validator

from app.schemas.common import InputModel, TimestampRead, reject_null

TaskTitle = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)]
EstimatedMinutes = Annotated[int, Field(strict=True, gt=0)]
DueDate = Annotated[AwareDatetime, AfterValidator(lambda value: value.astimezone(timezone.utc))]


class TaskCreate(InputModel):
    subject_id: UUID
    title: TaskTitle
    description: str = ""
    estimated_minutes: EstimatedMinutes
    due_date: DueDate


class TaskUpdate(InputModel):
    subject_id: UUID | None = None
    title: TaskTitle | None = None
    description: str | None = None
    estimated_minutes: EstimatedMinutes | None = None
    due_date: DueDate | None = None
    is_completed: StrictBool | None = None

    _fields_not_null = field_validator(
        "subject_id", "title", "description", "estimated_minutes", "due_date", "is_completed"
    )(reject_null)


class TaskRead(TimestampRead):
    id: UUID
    subject_id: UUID
    title: str
    description: str
    estimated_minutes: int
    due_date: datetime
    is_completed: bool

    @field_validator("due_date")
    @classmethod
    def utc_due_date(cls, value: datetime) -> datetime:
        return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value.astimezone(timezone.utc)
