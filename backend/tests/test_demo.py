from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import func, select

from app.core.config import Settings
from app.db.session import get_db
from app.main import create_app
from app.models import AvailabilitySlot, Subject, Task, User
from app.services.demo import DEMO_EMAIL
from app.services.planner import as_utc

PATH = "/api/v1/dev/demo-session"


@pytest.fixture
def demo_client(db_session):
    application = create_app(Settings(app_env="development", _env_file=None))
    application.dependency_overrides[get_db] = lambda: db_session
    with TestClient(application) as client:
        yield client


@pytest.mark.parametrize("environment", ["production", "testing", "staging", "Development", ""])
def test_route_absent_outside_exact_development(environment):
    with TestClient(create_app(Settings(app_env=environment, _env_file=None))) as client:
        assert client.post(PATH).status_code == 404
        assert PATH not in client.get("/openapi.json").json()["paths"]


def test_default_environment_is_fail_closed(monkeypatch):
    monkeypatch.delenv("APP_ENV")
    assert Settings(_env_file=None).app_env == "production"


def test_demo_seeds_once_with_dynamic_dates_and_ordinary_jwt(demo_client, db_session):
    before = datetime.now(timezone.utc)
    response = demo_client.post(PATH)
    assert response.status_code == 200
    assert set(response.json()) == {"access_token", "token_type"}
    assert response.headers["cache-control"] == "no-store"
    headers = {"Authorization": f"Bearer {response.json()['access_token']}"}
    profile = demo_client.get("/api/v1/users/me", headers=headers).json()
    assert profile["email"] == DEMO_EMAIL
    assert set(profile) == {"id", "email", "created_at", "updated_at"}
    user = db_session.scalar(select(User).where(User.email == DEMO_EMAIL))
    assert user.password_hash.startswith("$argon2")
    assert not any(hasattr(user, field) for field in ("is_admin", "role", "is_superuser"))
    tasks = db_session.scalars(select(Task).order_by(Task.due_date)).all()
    assert [task.estimated_minutes for task in tasks] == [90, 60, 120]
    for task, days in zip(tasks, (2, 4, 6)):
        assert before + timedelta(days=days) <= as_utc(task.due_date) <= datetime.now(timezone.utc) + timedelta(days=days)
    ids = [task.id for task in tasks]
    assert demo_client.post(PATH, json={}).status_code == 200
    assert [task.id for task in db_session.scalars(select(Task).order_by(Task.due_date))] == ids
    for model, count in ((User, 1), (Subject, 3), (Task, 3), (AvailabilitySlot, 7)):
        assert db_session.scalar(select(func.count()).select_from(model)) == count
    plan = demo_client.post("/api/v1/planner/plan", headers=headers, json={}).json()
    assert plan["summary"]["on_track_tasks"] == 3
    assert plan["summary"]["total_planned_minutes"] == 270


@pytest.mark.parametrize("existing", ["subject", "slot"])
def test_partial_demo_account_is_not_reseeded(demo_client, db_session, account_password_hash, existing):
    user = User(email=DEMO_EMAIL, password_hash=account_password_hash)
    db_session.add(user)
    db_session.flush()
    if existing == "subject":
        db_session.add(Subject(user_id=user.id, name="My edited data"))
    else:
        from datetime import time
        db_session.add(AvailabilitySlot(user_id=user.id, day_of_week=1,
                                       start_time=time(10), end_time=time(11)))
    db_session.commit()
    assert demo_client.post(PATH).status_code == 200
    assert db_session.scalar(select(func.count()).select_from(Task)) == 0
    assert db_session.scalar(select(func.count()).select_from(Subject)) == (existing == "subject")
    assert db_session.scalar(select(func.count()).select_from(AvailabilitySlot)) == (existing == "slot")


def test_demo_does_not_reset_edits_or_access_other_user(demo_client, db_session, accounts, auth_headers):
    subject = demo_client.post("/api/v1/subjects", headers=auth_headers[0], json={"name": "Private"}).json()
    response = demo_client.post(PATH)
    headers = {"Authorization": f"Bearer {response.json()['access_token']}"}
    tasks = demo_client.get("/api/v1/tasks", headers=headers).json()
    task_id = tasks[0]["id"]
    assert demo_client.patch(f"/api/v1/tasks/{task_id}", headers=headers, json={"title": "Edited", "is_completed": True}).status_code == 200
    assert demo_client.post(PATH).status_code == 200
    edited = demo_client.get(f"/api/v1/tasks/{task_id}", headers=headers).json()
    assert edited["title"] == "Edited" and edited["is_completed"]
    assert demo_client.get(f"/api/v1/subjects/{subject['id']}", headers=headers).status_code == 404
    assert demo_client.get(f"/api/v1/tasks/{task_id}", headers=auth_headers[0]).status_code == 404


@pytest.mark.parametrize("body", [{"email": "other@example.com"}, {"password": "not-accepted"}, {"user_id": "x"}])
def test_demo_accepts_no_credentials(demo_client, body):
    assert demo_client.post(PATH, json=body).status_code == 422
