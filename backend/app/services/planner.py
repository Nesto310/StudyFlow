from collections.abc import Sequence
from datetime import datetime, timedelta, timezone

from app.models import AvailabilitySlot, Task
from app.schemas.planner import (
    PlannerBlock, PlannerRequest, PlannerSummary, PlannerTaskSummary, StudyPlan,
)

MAX_STUDY_BLOCK_MINUTES = 90
BREAK_MINUTES = 10
MINUTE = timedelta(minutes=1)


def as_utc(value: datetime) -> datetime:
    # SQLite drops offsets; persisted task dates are normalized to UTC by the API.
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def availability_windows(
    slots: Sequence[AvailabilitySlot], start: datetime, end: datetime, offset: int,
) -> list[tuple[datetime, datetime]]:
    local_zone = timezone(timedelta(minutes=offset))
    first_day = start.astimezone(local_zone).date()
    last_day = end.astimezone(local_zone).date()
    windows = []
    for slot in slots:
        day = first_day + timedelta(days=(slot.day_of_week - first_day.isoweekday()) % 7)
        while day <= last_day:
            local_start = datetime.combine(day, slot.start_time, tzinfo=local_zone)
            local_end = datetime.combine(day, slot.end_time, tzinfo=local_zone)
            left, right = max(start, as_utc(local_start)), min(end, as_utc(local_end))
            if right > left:
                # Whole-minute blocks: round inward, never into the past or past a limit.
                rounded_left = left.replace(second=0, microsecond=0)
                if rounded_left < left:
                    rounded_left += MINUTE
                rounded_right = right.replace(second=0, microsecond=0)
                if rounded_left < rounded_right:
                    windows.append((rounded_left, rounded_right))
                if not slot.repeat_next_week:
                    break
            day += timedelta(days=7)

    # Overlapping/adjacent availability is one continuous window, not extra capacity.
    merged: list[tuple[datetime, datetime]] = []
    for left, right in sorted(windows):
        if merged and left <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(right, merged[-1][1]))
        else:
            merged.append((left, right))
    return merged


def generate_plan(
    tasks: Sequence[Task], slots: Sequence[AvailabilitySlot], request: PlannerRequest,
    *, now: datetime | None = None,
) -> StudyPlan:
    generated_at = as_utc(now or datetime.now(timezone.utc))
    start = as_utc(request.start_at or generated_at)
    end = start + timedelta(days=request.horizon_days)
    windows = availability_windows(slots, start, end, request.timezone_offset_minutes)
    pending = sorted(
        (task for task in tasks if not task.is_completed),
        key=lambda task: (as_utc(task.due_date), as_utc(task.created_at), str(task.id)),
    )
    remaining = {task.id: task.estimated_minutes for task in pending}
    blocks = []
    for left, right in windows:
        cursor = left
        while cursor + MINUTE <= right:
            for task in pending:
                if remaining[task.id] <= 0:
                    continue
                due = as_utc(task.due_date)
                limit = right if due <= start else min(right, due)
                capacity = (limit - cursor) // MINUTE
                if capacity <= 0:
                    continue
                minutes = min(remaining[task.id], capacity, MAX_STUDY_BLOCK_MINUTES)
                block_end = cursor + minutes * MINUTE
                blocks.append(PlannerBlock(
                    task_id=task.id, subject_id=task.subject_id,
                    subject_name=task.subject.name, task_title=task.title,
                    start_at=cursor, end_at=block_end, planned_minutes=minutes, due_date=due,
                ))
                remaining[task.id] -= minutes
                cursor = block_end + BREAK_MINUTES * MINUTE
                break
            else:
                break

    summaries = []
    for task in pending:
        due = as_utc(task.due_date)
        unplanned = remaining[task.id]
        risk = "overdue" if due <= start else "at_risk" if unplanned else "on_track"
        summaries.append(PlannerTaskSummary(
            task_id=task.id, subject_id=task.subject_id, subject_name=task.subject.name,
            task_title=task.title, due_date=due, estimated_minutes=task.estimated_minutes,
            planned_minutes=task.estimated_minutes - unplanned,
            unscheduled_minutes=unplanned, risk=risk,
        ))
    return StudyPlan(
        generated_at=generated_at, horizon_start=start, horizon_end=end,
        timezone_offset_minutes=request.timezone_offset_minutes, blocks=blocks, tasks=summaries,
        summary=PlannerSummary(
            total_pending_tasks=len(pending),
            total_planned_minutes=sum(task.planned_minutes for task in summaries),
            total_unscheduled_minutes=sum(task.unscheduled_minutes for task in summaries),
            total_available_minutes=sum((right - left) // MINUTE for left, right in windows),
            on_track_tasks=sum(task.risk == "on_track" for task in summaries),
            at_risk_tasks=sum(task.risk == "at_risk" for task in summaries),
            overdue_tasks=sum(task.risk == "overdue" for task in summaries),
        ),
    )
