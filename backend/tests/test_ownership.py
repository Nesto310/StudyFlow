from uuid import uuid4

import pytest


@pytest.mark.parametrize("resource", ["subjects", "tasks", "availability"])
@pytest.mark.parametrize("method", ["get", "patch", "delete"])
def test_foreign_resources_are_hidden_and_unchanged(client, auth_headers, api_resources, resource, method):
    snapshot = api_resources[resource]
    url = f"/api/v1/{resource}/{snapshot['id']}"
    changes = {"subjects": {"name": "Changed"}, "tasks": {"title": "Changed"}, "availability": {"day_of_week": 7}}
    kwargs = {"json": changes[resource]} if method == "patch" else {}
    denied = client.request(method, url, headers=auth_headers[1], **kwargs)
    assert denied.status_code == 404
    owned = client.get(url, headers=auth_headers[0])
    assert owned.status_code == 200
    assert owned.json() == snapshot


@pytest.mark.parametrize("resource", ["subjects", "tasks", "availability"])
def test_lists_do_not_leak_foreign_resources(client, auth_headers, api_resources, accounts, resource):
    response = client.get(
        f"/api/v1/{resource}?user_id={accounts[0].id}", headers=auth_headers[1]
    )
    assert response.status_code == 200
    assert response.json() == []
    assert client.get(f"/api/v1/{resource}", headers=auth_headers[0]).json() == [api_resources[resource]]


def test_task_cannot_be_created_in_foreign_subject(client, auth_headers, api_resources):
    response = client.post("/api/v1/tasks", headers=auth_headers[1], json={
        "subject_id": api_resources["subjects"]["id"], "title": "Forbidden",
        "estimated_minutes": 30, "due_date": "2026-10-01T18:00:00Z",
    })
    assert response.status_code == 404
    assert client.get("/api/v1/tasks", headers=auth_headers[0]).json() == [api_resources["tasks"]]
    assert client.get("/api/v1/tasks", headers=auth_headers[1]).json() == []


def test_task_cannot_be_transferred_to_foreign_subject(client, auth_headers, api_resources):
    foreign = client.post("/api/v1/subjects", headers=auth_headers[1], json={"name": "Other subject"})
    assert foreign.status_code == 201
    task = api_resources["tasks"]
    url = f"/api/v1/tasks/{task['id']}"
    response = client.patch(url, headers=auth_headers[0], json={
        "subject_id": foreign.json()["id"], "title": "Must not change",
    })
    assert response.status_code == 404
    assert client.get(url, headers=auth_headers[0]).json() == task
    assert client.get("/api/v1/tasks", headers=auth_headers[1]).json() == []


@pytest.mark.parametrize("resource", ["subjects", "tasks", "availability"])
@pytest.mark.parametrize("method", ["get", "patch", "delete"])
def test_missing_resources_return_404(client, auth_headers, resource, method):
    kwargs = {"json": {}} if method == "patch" else {}
    response = client.request(method, f"/api/v1/{resource}/{uuid4()}", headers=auth_headers[0], **kwargs)
    assert response.status_code == 404


@pytest.mark.parametrize("resource", ["subjects", "tasks", "availability"])
@pytest.mark.parametrize("operation", ["create", "list", "read", "update", "delete"])
def test_all_academic_operations_require_authentication(client, resource, operation):
    payloads = {
        "subjects": {"name": "Calculus"},
        "tasks": {"subject_id": str(uuid4()), "title": "Task", "estimated_minutes": 30, "due_date": "2026-10-01T18:00:00Z"},
        "availability": {"day_of_week": 1, "start_time": "19:00", "end_time": "20:00"},
    }
    methods = {"create": "post", "list": "get", "read": "get", "update": "patch", "delete": "delete"}
    url = f"/api/v1/{resource}"
    if operation in ("read", "update", "delete"):
        url += f"/{uuid4()}"
    kwargs = {"json": payloads[resource]} if operation in ("create", "update") else {}
    response = client.request(methods[operation], url, **kwargs)
    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Bearer"


@pytest.mark.parametrize("resource", ["subjects", "tasks", "availability"])
@pytest.mark.parametrize("operation", ["create", "update"])
def test_client_cannot_supply_ownership(client, auth_headers, accounts, api_resources, resource, operation):
    payloads = {
        "subjects": {"name": "Calculus"},
        "tasks": {"subject_id": api_resources["subjects"]["id"], "title": "Task", "estimated_minutes": 30, "due_date": "2026-10-01T18:00:00Z"},
        "availability": {"day_of_week": 1, "start_time": "19:00", "end_time": "20:00"},
    }
    url = f"/api/v1/{resource}"
    method = "post"
    if operation == "update":
        method = "patch"
        url += f"/{api_resources[resource]['id']}"
    response = client.request(method, url, headers=auth_headers[0], json={
        **payloads[resource], "user_id": str(accounts[1].id),
    })
    assert response.status_code == 422
    assert client.get(f"/api/v1/{resource}", headers=auth_headers[0]).json() == [api_resources[resource]]
