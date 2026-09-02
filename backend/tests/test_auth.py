from datetime import datetime, timedelta, timezone
from secrets import token_urlsafe
from unittest.mock import patch
from uuid import uuid4

import jwt
import pytest
from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.core.config import Settings, get_settings
from app.core.security import DUMMY_PASSWORD_HASH, create_access_token, verify_password
from app.models import User


def test_registration_normalizes_email_and_stores_argon2(client, db_session, account_password):
    response = client.post("/api/v1/auth/register", json={
        "email": " Student@Example.com ", "password": account_password,
    })
    assert response.status_code == 201
    assert set(response.json()) == {"id", "email", "created_at", "updated_at"}
    assert response.json()["email"] == "student@example.com"
    user = db_session.scalars(select(User).where(User.email == "student@example.com")).one()
    assert user.password_hash != account_password
    assert user.password_hash.startswith("$argon2id$")
    assert verify_password(account_password, user.password_hash)
    assert account_password not in response.text
    assert "password_hash" not in response.text


@pytest.mark.parametrize("email", ["student@example.com", " Student@Example.com "])
def test_duplicate_normalized_email_is_conflict(client, account_password, email):
    assert client.post("/api/v1/auth/register", json={
        "email": "Student@Example.com", "password": account_password,
    }).status_code == 201
    response = client.post("/api/v1/auth/register", json={"email": email, "password": account_password})
    assert response.status_code == 409
    assert "password_hash" not in response.text


@pytest.mark.parametrize("changes", [
    {"email": "invalid"}, {"password": "short"}, {"password": "x" * 129},
    {"password": None}, {"user_id": str(uuid4())},
])
def test_registration_validation_never_echoes_password(client, changes, account_password):
    payload = {"email": "student@example.com", "password": account_password, **changes}
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 422
    assert all("input" not in error for error in response.json()["detail"])
    assert account_password not in response.text
    assert "password_hash" not in response.text


def test_login_form_and_current_user(client, accounts, account_password):
    before = datetime.now(timezone.utc).timestamp()
    response = client.post("/api/v1/auth/token", data={
        "username": " USER-A@EXAMPLE.COM ", "password": account_password,
        "grant_type": "password",
    })
    assert response.status_code == 200
    assert set(response.json()) == {"access_token", "token_type"}
    assert response.json()["token_type"] == "bearer"
    assert response.headers["Cache-Control"] == "no-store"
    token = response.json()["access_token"]
    settings = get_settings()
    payload = jwt.decode(token, settings.jwt_secret_key.get_secret_value(), algorithms=["HS256"])
    assert set(payload) == {"sub", "exp"}
    assert payload["sub"] == str(accounts[0].id)
    assert 1798 <= payload["exp"] - before <= 1801
    me = client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["id"] == str(accounts[0].id)
    assert set(me.json()) == {"id", "email", "created_at", "updated_at"}


def test_login_failure_is_generic_and_unknown_email_checks_dummy(client, accounts):
    with patch("app.api.routes.auth.verify_password", wraps=verify_password) as verify:
        missing = client.post("/api/v1/auth/token", data={
            "username": "missing@example.com", "password": "incorrect-password",
        })
        verify.assert_called_once_with("incorrect-password", DUMMY_PASSWORD_HASH)
    wrong = client.post("/api/v1/auth/token", data={
        "username": accounts[0].email, "password": "incorrect-password",
    })
    for response in (missing, wrong):
        assert response.status_code == 401
        assert response.headers["WWW-Authenticate"] == "Bearer"
    assert missing.json() == wrong.json() == {"detail": "Incorrect email or password"}


@pytest.mark.parametrize("case", [
    "missing", "invalid", "wrong_scheme", "expired", "wrong_signature", "wrong_algorithm",
    "unsigned", "missing_sub", "missing_exp", "invalid_uuid", "non_string_sub",
    "invalid_exp", "null_exp", "fractional_exp", "unknown_user",
])
def test_invalid_authentication_returns_401(client, accounts, case):
    payload = {"sub": str(accounts[0].id), "exp": datetime.now(timezone.utc) + timedelta(minutes=1)}
    key = get_settings().jwt_secret_key.get_secret_value()
    algorithm = "HS256"
    if case == "expired":
        payload["exp"] = datetime.now(timezone.utc) - timedelta(seconds=10)
    elif case == "missing_sub":
        del payload["sub"]
    elif case == "missing_exp":
        del payload["exp"]
    elif case == "invalid_uuid":
        payload["sub"] = "not-a-uuid"
    elif case == "non_string_sub":
        payload["sub"] = 42
    elif case == "invalid_exp":
        payload["exp"] = []
    elif case == "null_exp":
        payload["exp"] = None
    elif case == "fractional_exp":
        payload["exp"] = datetime.now(timezone.utc).timestamp() + 60
    elif case == "unknown_user":
        payload["sub"] = str(uuid4())
    elif case == "wrong_signature":
        key = token_urlsafe(48)
    elif case == "wrong_algorithm":
        algorithm = "HS384"
    elif case == "unsigned":
        algorithm, key = "none", ""
    token = jwt.encode(payload, key, algorithm=algorithm)
    headers = {"Authorization": f"Bearer {token}"}
    if case == "missing":
        headers = {}
    elif case == "invalid":
        headers = {"Authorization": "Bearer invalid-token"}
    elif case == "wrong_scheme":
        headers = {"Authorization": f"Basic {token}"}
    response = client.get("/api/v1/users/me", headers=headers)
    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Bearer"
    assert response.json() == {"detail": "Could not validate credentials"}


def test_token_expiration_is_configurable(monkeypatch):
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "5")
    get_settings.cache_clear()
    try:
        token = create_access_token(uuid4())
        payload = jwt.decode(token, get_settings().jwt_secret_key.get_secret_value(), algorithms=["HS256"])
        assert 298 <= payload["exp"] - datetime.now(timezone.utc).timestamp() <= 301
    finally:
        get_settings.cache_clear()


@pytest.mark.parametrize("secret", [None, "too-short", " " * 40, "replace-with-a-secure-random-secret"])
def test_settings_require_new_secret(monkeypatch, secret):
    if secret is None:
        monkeypatch.delenv("JWT_SECRET_KEY")
    else:
        monkeypatch.setenv("JWT_SECRET_KEY", secret)
    with pytest.raises(ValidationError) as exc:
        Settings(_env_file=None)
    if secret:
        assert secret not in str(exc.value)


def test_registration_race_rolls_back_without_internal_details(client, db_session, account_password):
    with patch.object(db_session, "commit", side_effect=IntegrityError("private SQL", {}, Exception("private details"))), \
         patch.object(db_session, "rollback", wraps=db_session.rollback) as rollback:
        response = client.post("/api/v1/auth/register", json={
            "email": "race@example.com", "password": account_password,
        })
        rollback.assert_called_once()
    assert response.status_code == 409
    assert response.json() == {"detail": "Email already registered"}
    assert db_session.scalar(select(User.id).where(User.email == "race@example.com")) is None


def test_openapi_declares_oauth_form_and_all_endpoints(client):
    assert client.get("/docs").status_code == 200
    schema = client.get("/openapi.json").json()
    flow = schema["components"]["securitySchemes"]["OAuth2PasswordBearer"]["flows"]["password"]
    assert flow["tokenUrl"] == "/api/v1/auth/token"
    assert "/api/v1/auth/register" in schema["paths"]
    assert "/api/v1/users/me" in schema["paths"]
    assert "application/x-www-form-urlencoded" in schema["paths"]["/api/v1/auth/token"]["post"]["requestBody"]["content"]
    for resource, parameter in (("subjects", "subject_id"), ("tasks", "task_id"), ("availability", "slot_id")):
        assert {"get", "post"} <= schema["paths"][f"/api/v1/{resource}"].keys()
        item = schema["paths"][f"/api/v1/{resource}/{{{parameter}}}"]
        for method in ("get", "patch", "delete"):
            assert item[method]["security"] == [{"OAuth2PasswordBearer": []}]
    assert "password_hash" not in schema["components"]["schemas"]["UserRead"]["properties"]
