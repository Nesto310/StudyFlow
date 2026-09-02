import os
from collections.abc import Generator
from secrets import token_urlsafe

import pytest
from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

os.environ["DATABASE_URL"] = "sqlite+pysqlite:///:memory:"
os.environ["APP_NAME"] = "StudyFlow API"
os.environ["APP_ENV"] = "testing"
os.environ["JWT_SECRET_KEY"] = token_urlsafe(48)
os.environ["JWT_ALGORITHM"] = "HS256"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "30"

from app.db.base import Base  # noqa: E402
import app.models  # noqa: E402, F401


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    @event.listens_for(engine, "connect")
    def enable_sqlite_foreign_keys(dbapi_connection, _connection_record) -> None:
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    Base.metadata.create_all(engine)
    testing_session = sessionmaker(
        bind=engine,
        class_=Session,
        expire_on_commit=False,
    )

    with testing_session() as session:
        yield session

    Base.metadata.drop_all(engine)
    engine.dispose()


@pytest.fixture
def client(db_session):
    from fastapi.testclient import TestClient

    from app.db.session import get_db
    from app.main import app

    def override_get_db():
        yield db_session

    original_overrides = app.dependency_overrides.copy()
    app.dependency_overrides[get_db] = override_get_db
    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        app.dependency_overrides.clear()
        app.dependency_overrides.update(original_overrides)


@pytest.fixture(scope="session")
def account_password():
    return "studyflow-test-password"


@pytest.fixture(scope="session")
def account_password_hash(account_password):
    from app.core.security import hash_password

    return hash_password(account_password)


@pytest.fixture
def accounts(db_session, account_password_hash):
    from app.models import User

    users = [
        User(email="user-a@example.com", password_hash=account_password_hash),
        User(email="user-b@example.com", password_hash=account_password_hash),
    ]
    db_session.add_all(users)
    db_session.commit()
    return users


@pytest.fixture
def auth_headers(accounts):
    from app.core.security import create_access_token

    return [
        {"Authorization": f"Bearer {create_access_token(user.id)}"}
        for user in accounts
    ]


@pytest.fixture
def api_resources(client, auth_headers):
    headers = auth_headers[0]
    subject = client.post("/api/v1/subjects", headers=headers, json={"name": "Calculus"})
    assert subject.status_code == 201
    task = client.post("/api/v1/tasks", headers=headers, json={
        "subject_id": subject.json()["id"], "title": "Derivatives",
        "estimated_minutes": 60, "due_date": "2026-10-01T18:00:00Z",
    })
    assert task.status_code == 201
    slot = client.post("/api/v1/availability", headers=headers, json={
        "day_of_week": 2, "start_time": "19:00", "end_time": "21:00",
    })
    assert slot.status_code == 201
    return {"subjects": subject.json(), "tasks": task.json(), "availability": slot.json()}
