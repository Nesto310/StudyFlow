from datetime import datetime, time, timedelta, timezone
from uuid import UUID, uuid4

import pytest
from sqlalchemy import inspect, select

from app.models import AvailabilitySlot, Subject, Task
from app.schemas.planner import PlannerRequest
from app.services.planner import availability_windows, generate_plan

START = datetime(2026, 9, 7, 18, tzinfo=timezone.utc)  # Monday


def task(minutes=60, *, due=None, number=1, completed=False, created=None):
    subject = Subject(id=uuid4(), name="Algorithms", user_id=uuid4())
    return Task(id=UUID(int=number), subject=subject, subject_id=subject.id,
                title=f"Task {number}", estimated_minutes=minutes,
                due_date=due or START + timedelta(days=10), is_completed=completed,
                created_at=created or START - timedelta(days=1))


def slot(day=1, start=19, end=21, repeat=False):
    return AvailabilitySlot(id=uuid4(), user_id=uuid4(), day_of_week=day,
                            start_time=time(start), end_time=time(end),
                            repeat_next_week=repeat)


def plan(tasks=(), slots=(), **kwargs):
    return generate_plan(tasks, slots, PlannerRequest(start_at=START, **kwargs), now=START)


def test_edf_and_completed_tasks():
    later = task(number=2, due=START + timedelta(days=5))
    earlier = task(number=1, due=START + timedelta(days=1))
    result = plan([later, task(number=3, completed=True), earlier], [slot(end=22)])
    assert [item.task_id for item in result.tasks] == [earlier.id, later.id]
    assert [block.task_id for block in result.blocks] == [earlier.id, later.id]
    assert result.summary.total_pending_tasks == 2


def test_deterministic_ties_by_creation_then_id():
    tasks = [task(number=3), task(number=2), task(number=1, created=START)]
    result = plan(tasks, [slot(end=23)])
    assert [item.task_id.int for item in result.tasks] == [2, 3, 1]
    assert result == plan(list(reversed(tasks)), [slot(end=23)])


def test_split_across_days_uses_estimate():
    result = plan([task(180)], [slot(end=20), slot(day=2), slot(day=3)])
    assert [block.planned_minutes for block in result.blocks] == [60, 90, 20, 10]
    assert result.summary.total_planned_minutes == 180
    assert result.tasks[0].risk == "on_track"


def test_maximum_block_and_break_within_window():
    result = plan([task(180)], [slot(end=23)])
    assert [block.planned_minutes for block in result.blocks] == [90, 90]
    assert result.blocks[1].start_at - result.blocks[0].end_at == timedelta(minutes=10)
    assert result.summary.total_available_minutes == 240


def test_multiple_tasks_share_slot_and_break():
    result = plan([task(45), task(60, number=2)], [slot()])
    assert [block.planned_minutes for block in result.blocks] == [45, 60]
    assert result.blocks[1].start_at.hour == 19
    assert result.blocks[1].start_at.minute == 55
    assert result.summary.on_track_tasks == 2


def test_break_cannot_leave_positive_block():
    result = plan([task(100)], [slot(end=20)])
    assert [block.planned_minutes for block in result.blocks] == [60]
    assert result.tasks[0].unscheduled_minutes == 40


def test_future_deadline_clips_task_without_blocking_later_tasks():
    urgent = task(180, due=START + timedelta(hours=2, minutes=15))
    result = plan([urgent, task(60, number=2)], [slot(end=22)])
    first = result.tasks[0]
    assert (first.planned_minutes, first.unscheduled_minutes, first.risk) == (75, 105, "at_risk")
    assert all(block.end_at <= urgent.due_date for block in result.blocks if block.task_id == urgent.id)
    assert result.tasks[1].planned_minutes == 60


@pytest.mark.parametrize("due", [START, START - timedelta(days=3)])
def test_overdue_still_scheduled_and_never_on_track(due):
    result = plan([task(due=due), task(number=2)], [slot(end=22)])
    assert result.tasks[0].risk == "overdue"
    assert result.tasks[0].planned_minutes == 60
    assert result.blocks[0].task_id.int == 1
    assert result.summary.overdue_tasks == 1


def test_no_availability():
    result = plan([task(), task(number=2, due=START)])
    assert result.blocks == []
    assert result.summary.total_unscheduled_minutes == 120
    assert result.summary.at_risk_tasks == result.summary.overdue_tasks == 1


def test_no_tasks_is_valid():
    result = plan(slots=[slot()])
    assert result.blocks == result.tasks == []
    assert result.summary.total_pending_tasks == 0
    assert result.summary.total_available_minutes == 120


@pytest.mark.parametrize("repeat,count", [(False, 1), (True, 2)])
def test_repeat_semantics(repeat, count):
    result = plan([task(1000, due=START + timedelta(days=30))], [slot(end=20, repeat=repeat)])
    assert len(result.blocks) == count
    assert result.summary.total_available_minutes == count * 60


def test_past_occurrence_of_nonrepeating_slot_uses_next_week():
    result = plan([task()], [slot(start=16, end=17)])
    assert result.blocks[0].start_at == START + timedelta(days=7, hours=-2)


def test_partial_today_and_horizon_end_are_clipped():
    start = START.replace(hour=19, minute=30)
    result = generate_plan([task(500)], [slot(), slot(day=2)],
                           PlannerRequest(start_at=start, horizon_days=1), now=START)
    assert result.blocks[0].start_at == start
    assert result.summary.total_available_minutes == 120
    assert result.blocks[-1].end_at == start + timedelta(days=1)


@pytest.mark.parametrize("offset,hour", [(-180, 22), (180, 16), (-840, 9), (840, 5)])
def test_fixed_local_offset(offset, hour):
    start = START.replace(hour=0)
    windows = availability_windows([slot()], start, start + timedelta(days=7), offset)
    assert windows[0][0].hour == hour
    assert windows[0][0].astimezone(timezone(timedelta(minutes=offset))).isoweekday() == 1
    assert windows[0][0].tzinfo == timezone.utc


def test_offsets_may_cross_utc_date_boundary():
    result = plan([task()], [slot(start=22, end=23)], timezone_offset_minutes=-180)
    assert result.blocks[0].start_at == datetime(2026, 9, 8, 1, tzinfo=timezone.utc)


def test_overlapping_and_adjacent_slots_are_union_not_extra_capacity():
    result = plan([task(500)], [slot(), slot(start=20, end=22), slot(start=22, end=23)])
    assert result.summary.total_available_minutes == 240
    assert [b.planned_minutes for b in result.blocks] == [90, 90, 40]
    assert all(b.start_at - a.end_at == timedelta(minutes=10)
               for a, b in zip(result.blocks, result.blocks[1:]))


def test_subminute_boundaries_round_inward():
    start = START.replace(hour=19, second=30)
    due = START.replace(hour=20, second=15)
    result = generate_plan([task(90, due=due)], [slot()], PlannerRequest(start_at=start), now=START)
    assert result.blocks[0].start_at == start.replace(minute=1, second=0)
    assert result.blocks[0].end_at <= due
    assert result.tasks[0].planned_minutes == 59


def test_default_start_and_horizon_use_utc_now():
    result = generate_plan([], [], PlannerRequest(), now=START)
    assert result.generated_at == result.horizon_start == START
    assert result.horizon_end == START + timedelta(days=14)


def test_planner_requires_authentication(client):
    assert client.post("/api/v1/planner/plan", json={}).status_code == 401


@pytest.mark.parametrize("body", [
    {"horizon_days": 0}, {"horizon_days": 31}, {"horizon_days": True}, {"horizon_days": 1.5},
    {"timezone_offset_minutes": -841}, {"timezone_offset_minutes": 841},
    {"timezone_offset_minutes": "0"}, {"start_at": "2026-09-07T18:00:00"},
    {"start_at": "9999-12-31T23:59:00Z"}, {"start_at": "0001-01-01T00:00:00Z"},
    {"user_id": "someone"}, {"task_ids": []}, {"tasks": []}, {"availability": []},
])
def test_rejects_invalid_or_arbitrary_input(client, auth_headers, body):
    assert client.post("/api/v1/planner/plan", headers=auth_headers[0], json=body).status_code == 422


@pytest.mark.parametrize("horizon,offset", [(1, -840), (30, 840)])
def test_request_bounds_accepted(client, auth_headers, horizon, offset):
    response = client.post("/api/v1/planner/plan", headers=auth_headers[0], json={
        "start_at": START.isoformat(), "horizon_days": horizon, "timezone_offset_minutes": offset,
    })
    assert response.status_code == 200


def snapshot(db):
    return [[{column.key: getattr(row, column.key) for column in inspect(model).columns}
             for row in db.scalars(select(model).order_by(model.id)).all()]
            for model in (Subject, Task, AvailabilitySlot)]


def test_api_ownership_read_only_and_completed_filter(client, auth_headers, db_session):
    task_ids = []
    for index, headers in enumerate(auth_headers):
        subject_id = client.post("/api/v1/subjects", headers=headers, json={"name": f"Subject {index}"}).json()["id"]
        created = client.post("/api/v1/tasks", headers=headers, json={
            "subject_id": subject_id, "title": f"Task {index}", "estimated_minutes": 80,
            "due_date": (START + timedelta(days=20)).isoformat(),
        }).json()
        task_ids.append(created["id"])
        client.post("/api/v1/availability", headers=headers, json={
            "day_of_week": index + 1, "start_time": "19:00", "end_time": "21:00",
            "repeat_next_week": False,
        })
    before = snapshot(db_session)
    for index, headers in enumerate(auth_headers):
        response = client.post("/api/v1/planner/plan", headers=headers, json={"start_at": START.isoformat()})
        assert response.status_code == 200
        data = response.json()
        assert [t["task_id"] for t in data["tasks"]] == [task_ids[index]]
        assert data["blocks"][0]["subject_name"] == f"Subject {index}"
        assert datetime.fromisoformat(data["blocks"][0]["start_at"]).isoweekday() == index + 1
        assert data["summary"]["total_available_minutes"] == 120
        assert data["generated_at"].endswith("Z")
    db_session.expire_all()
    assert snapshot(db_session) == before
    client.patch(f"/api/v1/tasks/{task_ids[0]}", headers=auth_headers[0], json={"is_completed": True})
    assert client.post("/api/v1/planner/plan", headers=auth_headers[0], json={}).json()["tasks"] == []
