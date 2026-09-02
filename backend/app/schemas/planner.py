from datetime import timedelta, timezone
from typing import Literal
from uuid import UUID

from pydantic import AwareDatetime, BaseModel, Field, model_validator

from app.schemas.common import InputModel

Risk = Literal["on_track", "at_risk", "overdue"]


class PlannerRequest(InputModel):
    start_at: AwareDatetime | None = None
    horizon_days: int = Field(default=14, ge=1, le=30, strict=True)
    timezone_offset_minutes: int = Field(default=0, ge=-840, le=840, strict=True)

    @model_validator(mode="after")
    def representable_horizon(self):
        if self.start_at is not None:
            try:
                start = self.start_at.astimezone(timezone.utc)
                start - timedelta(days=1)
                start + timedelta(days=self.horizon_days + 7)
            except (OverflowError, ValueError):
                raise ValueError("Planning horizon is outside the supported date range") from None
        return self


class PlannerBlock(BaseModel):
    task_id: UUID
    subject_id: UUID
    subject_name: str
    task_title: str
    start_at: AwareDatetime
    end_at: AwareDatetime
    planned_minutes: int
    due_date: AwareDatetime


class PlannerTaskSummary(BaseModel):
    task_id: UUID
    subject_id: UUID
    subject_name: str
    task_title: str
    due_date: AwareDatetime
    estimated_minutes: int
    planned_minutes: int
    unscheduled_minutes: int
    risk: Risk


class PlannerSummary(BaseModel):
    total_pending_tasks: int
    total_planned_minutes: int
    total_unscheduled_minutes: int
    total_available_minutes: int
    on_track_tasks: int
    at_risk_tasks: int
    overdue_tasks: int


class StudyPlan(BaseModel):
    generated_at: AwareDatetime
    horizon_start: AwareDatetime
    horizon_end: AwareDatetime
    timezone_offset_minutes: int
    blocks: list[PlannerBlock]
    tasks: list[PlannerTaskSummary]
    summary: PlannerSummary
