from datetime import time
from typing import Annotated
from uuid import UUID

from pydantic import AfterValidator, Field, StrictBool, model_validator, field_validator

from app.schemas.common import InputModel, TimestampRead, reject_null


def local_time(value: time) -> time:
    if value.tzinfo is not None:
        raise ValueError("Weekly times must not include a timezone")
    return value


DayOfWeek = Annotated[int, Field(strict=True, ge=1, le=7)]
LocalTime = Annotated[time, AfterValidator(local_time)]


class AvailabilityCreate(InputModel):
    day_of_week: DayOfWeek
    start_time: LocalTime
    end_time: LocalTime
    repeat_next_week: StrictBool = True

    @model_validator(mode="after")
    def ordered_times(self):
        if self.start_time >= self.end_time:
            raise ValueError("start_time must be earlier than end_time")
        return self


class AvailabilityUpdate(InputModel):
    day_of_week: DayOfWeek | None = None
    start_time: LocalTime | None = None
    end_time: LocalTime | None = None
    repeat_next_week: StrictBool | None = None

    _fields_not_null = field_validator(
        "day_of_week", "start_time", "end_time", "repeat_next_week"
    )(reject_null)


class AvailabilityRead(TimestampRead):
    id: UUID
    user_id: UUID
    day_of_week: int
    start_time: time
    end_time: time
    repeat_next_week: bool
