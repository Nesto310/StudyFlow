from unittest.mock import patch
from uuid import uuid4

import pytest
from sqlalchemy.exc import IntegrityError


@pytest.mark.parametrize("changes", [
    {"name": ""}, {"name": "   "}, {"name": None}, {"name": "x" * 161},
    {"teacher": "x" * 161},
])
@pytest.mark.parametrize("method", ["post", "patch"])
def test_subject_validation(client, auth_headers, api_resources, changes, method):
    url = "/api/v1/subjects"
    if method == "patch":
        url += f"/{api_resources['subjects']['id']}"
    response = client.request(method, url, headers=auth_headers[0], json={"name": "Name", **changes})
    assert response.status_code == 422
    assert client.get("/api/v1/subjects", headers=auth_headers[0]).json() == [api_resources["subjects"]]


@pytest.mark.parametrize("changes", [
    {"title": " "}, {"title": None}, {"title": "x" * 201},
    {"estimated_minutes": 0}, {"estimated_minutes": -1}, {"estimated_minutes": 1.5},
    {"estimated_minutes": True}, {"estimated_minutes": None},
    {"due_date": "2026-10-01T18:00:00"}, {"due_date": "invalid"}, {"due_date": None},
    {"subject_id": "invalid"}, {"subject_id": None}, {"description": None},
])
@pytest.mark.parametrize("method", ["post", "patch"])
def test_task_validation(client, auth_headers, api_resources, changes, method):
    payload = {
        "subject_id": api_resources["subjects"]["id"], "title": "Task",
        "estimated_minutes": 30, "due_date": "2026-10-01T18:00:00Z", **changes,
    }
    url = "/api/v1/tasks"
    if method == "patch":
        url += f"/{api_resources['tasks']['id']}"
    response = client.request(method, url, headers=auth_headers[0], json=payload)
    assert response.status_code == 422
    assert client.get("/api/v1/tasks", headers=auth_headers[0]).json() == [api_resources["tasks"]]


def test_task_cannot_start_completed(client, auth_headers, api_resources):
    response = client.post("/api/v1/tasks", headers=auth_headers[0], json={
        "subject_id": api_resources["subjects"]["id"], "title": "Task",
        "estimated_minutes": 30, "due_date": "2026-10-01T18:00:00Z", "is_completed": True,
    })
    assert response.status_code == 422


def test_missing_task_subject_is_404(client, auth_headers, api_resources):
    payload = {"subject_id": str(uuid4()), "title": "Task", "estimated_minutes": 30, "due_date": "2026-10-01T18:00:00Z"}
    assert client.post("/api/v1/tasks", headers=auth_headers[0], json=payload).status_code == 404
    assert client.patch(f"/api/v1/tasks/{api_resources['tasks']['id']}", headers=auth_headers[0], json={"subject_id": payload["subject_id"]}).status_code == 404


@pytest.mark.parametrize("changes", [
    {"day_of_week": 0}, {"day_of_week": 8}, {"day_of_week": None},
    {"start_time": "21:00", "end_time": "20:00"},
    {"start_time": "20:00", "end_time": "20:00"},
    {"start_time": "19:00:00Z"}, {"start_time": None}, {"end_time": None},
    {"repeat_next_week": None}, {"end_time": "invalid"},
])
@pytest.mark.parametrize("method", ["post", "patch"])
def test_availability_validation(client, auth_headers, api_resources, changes, method):
    url = "/api/v1/availability"
    if method == "patch":
        url += f"/{api_resources['availability']['id']}"
    response = client.request(method, url, headers=auth_headers[0], json={
        "day_of_week": 1, "start_time": "19:00", "end_time": "20:00", **changes,
    })
    assert response.status_code == 422
    assert client.get("/api/v1/availability", headers=auth_headers[0]).json() == [api_resources["availability"]]


@pytest.mark.parametrize("changes", [{"start_time": "22:00"}, {"end_time": "18:00"}, {"start_time": "21:00"}])
def test_partial_availability_is_validated_against_stored_values(client, auth_headers, api_resources, changes):
    slot = api_resources["availability"]
    url = f"/api/v1/availability/{slot['id']}"
    assert client.patch(url, headers=auth_headers[0], json=changes).status_code == 422
    assert client.get(url, headers=auth_headers[0]).json() == slot


@pytest.mark.parametrize("resource", ["subjects", "tasks", "availability"])
def test_empty_patch_preserves_values(client, auth_headers, api_resources, resource):
    original = api_resources[resource]
    response = client.patch(f"/api/v1/{resource}/{original['id']}", headers=auth_headers[0], json={})
    assert response.status_code == 200
    assert response.json() == original


def test_crud_integrity_error_is_sanitized_and_rolled_back(client, db_session, auth_headers):
    with patch.object(db_session, "commit", side_effect=IntegrityError("private SQL", {}, Exception("private details"))), \
         patch.object(db_session, "rollback", wraps=db_session.rollback) as rollback:
        response = client.post("/api/v1/subjects", headers=auth_headers[0], json={"name": "Conflict"})
        rollback.assert_called_once()
    assert response.status_code == 409
    assert response.json() == {"detail": "Operation conflicts with existing data"}
    assert client.get("/api/v1/subjects", headers=auth_headers[0]).json() == []
