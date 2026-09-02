from uuid import UUID

from app.models import Subject, Task


def test_subject_crud(client, auth_headers):
    headers = auth_headers[0]
    response = client.post("/api/v1/subjects", headers=headers, json={"name": " Calculus ", "teacher": " Ada "})
    assert response.status_code == 201
    subject = response.json()
    url = f"/api/v1/subjects/{subject['id']}"
    assert subject["name"] == "Calculus"
    assert subject["teacher"] == "Ada"
    assert client.get(url, headers=headers).json() == subject
    assert client.get("/api/v1/subjects", headers=headers).json() == [subject]
    updated = client.patch(url, headers=headers, json={"name": " Algebra "})
    assert updated.status_code == 200
    assert updated.json()["name"] == "Algebra"
    assert updated.json()["teacher"] == "Ada"
    assert client.patch(url, headers=headers, json={"teacher": None}).json()["teacher"] is None
    deleted = client.delete(url, headers=headers)
    assert deleted.status_code == 204 and deleted.content == b""
    assert client.get(url, headers=headers).status_code == 404
    assert client.get("/api/v1/subjects", headers=headers).json() == []


def test_subject_with_tasks_cannot_be_deleted(client, auth_headers, api_resources, db_session):
    subject = api_resources["subjects"]
    task = api_resources["tasks"]
    response = client.delete(f"/api/v1/subjects/{subject['id']}", headers=auth_headers[0])
    assert response.status_code == 409
    assert response.json() == {"detail": "Subject has linked tasks"}
    assert db_session.get(Subject, UUID(subject["id"])) is not None
    assert db_session.get(Task, UUID(task["id"])) is not None
    assert client.get(f"/api/v1/subjects/{subject['id']}", headers=auth_headers[0]).status_code == 200
    assert client.get(f"/api/v1/tasks/{task['id']}", headers=auth_headers[0]).status_code == 200


def test_task_crud_and_transfer_to_owned_subject(client, auth_headers, api_resources):
    headers = auth_headers[0]
    response = client.post("/api/v1/tasks", headers=headers, json={
        "subject_id": api_resources["subjects"]["id"], "title": " Read chapter ",
        "estimated_minutes": 30, "due_date": "2026-10-01T15:00:00-03:00",
    })
    assert response.status_code == 201
    task = response.json()
    assert task["title"] == "Read chapter"
    assert task["description"] == ""
    assert task["is_completed"] is False
    assert task["due_date"] == "2026-10-01T18:00:00Z"
    url = f"/api/v1/tasks/{task['id']}"
    assert client.get(url, headers=headers).json() == task
    assert task in client.get("/api/v1/tasks", headers=headers).json()
    subject = client.post("/api/v1/subjects", headers=headers, json={"name": "Physics"}).json()
    updated = client.patch(url, headers=headers, json={
        "subject_id": subject["id"], "title": " Review ", "description": "Notes", "is_completed": True,
    })
    assert updated.status_code == 200
    assert updated.json()["subject_id"] == subject["id"]
    assert updated.json()["title"] == "Review"
    assert updated.json()["description"] == "Notes"
    assert updated.json()["is_completed"] is True
    deleted = client.delete(url, headers=headers)
    assert deleted.status_code == 204 and deleted.content == b""
    assert client.get(url, headers=headers).status_code == 404


def test_availability_crud(client, auth_headers):
    headers = auth_headers[0]
    response = client.post("/api/v1/availability", headers=headers, json={
        "day_of_week": 1, "start_time": "19:00", "end_time": "20:00",
    })
    assert response.status_code == 201
    slot = response.json()
    assert slot["repeat_next_week"] is True
    url = f"/api/v1/availability/{slot['id']}"
    assert client.get(url, headers=headers).json() == slot
    assert client.get("/api/v1/availability", headers=headers).json() == [slot]
    updated = client.patch(url, headers=headers, json={
        "day_of_week": 7, "start_time": "20:00", "end_time": "22:00", "repeat_next_week": False,
    })
    assert updated.status_code == 200
    assert updated.json()["day_of_week"] == 7
    assert updated.json()["repeat_next_week"] is False
    partial = client.patch(url, headers=headers, json={"start_time": "21:00"})
    assert partial.status_code == 200
    assert partial.json()["end_time"] == "22:00:00"
    assert partial.json()["start_time"] == "21:00:00"
    deleted = client.delete(url, headers=headers)
    assert deleted.status_code == 204 and deleted.content == b""
    assert client.get(url, headers=headers).status_code == 404
