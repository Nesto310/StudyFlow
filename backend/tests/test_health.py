from collections.abc import Generator

from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.main import app

client = TestClient(app)


def test_health_returns_service_status() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "service": "StudyFlow API",
    }


def test_database_health_uses_database_dependency(db_session: Session) -> None:
    def override_get_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        response = client.get("/health/db")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "service": "StudyFlow API",
        "database": "ok",
    }


def test_database_health_hides_connection_errors() -> None:
    class UnavailableSession:
        def execute(self, _statement) -> None:
            raise OperationalError("SELECT 1", {}, Exception("private details"))

    def override_get_db():
        yield UnavailableSession()

    app.dependency_overrides[get_db] = override_get_db
    try:
        response = client.get("/health/db")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 503
    assert response.json() == {"detail": "Database unavailable"}
