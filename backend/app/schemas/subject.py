from typing import Annotated
from uuid import UUID

from pydantic import StringConstraints, field_validator

from app.schemas.common import InputModel, TimestampRead, reject_null

SubjectName = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=160)]
TeacherName = Annotated[str, StringConstraints(strip_whitespace=True, max_length=160)]


class SubjectCreate(InputModel):
    name: SubjectName
    teacher: TeacherName | None = None


class SubjectUpdate(InputModel):
    name: SubjectName | None = None
    teacher: TeacherName | None = None

    _name_not_null = field_validator("name")(reject_null)


class SubjectRead(TimestampRead):
    id: UUID
    user_id: UUID
    name: str
    teacher: str | None
