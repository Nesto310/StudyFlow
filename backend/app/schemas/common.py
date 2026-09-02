from datetime import datetime, timezone
from typing import TypeVar

from pydantic import BaseModel, ConfigDict, field_validator

T = TypeVar("T")


def reject_null(value: T) -> T:
    if value is None:
        raise ValueError("Field cannot be null")
    return value


class InputModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class TimestampRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    created_at: datetime
    updated_at: datetime

    @field_validator("created_at", "updated_at")
    @classmethod
    def utc_timestamps(cls, value: datetime) -> datetime:
        # SQLite drops timezone information in isolated tests; stored dates are UTC.
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)
