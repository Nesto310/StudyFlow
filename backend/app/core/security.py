from datetime import datetime, timedelta, timezone
from secrets import token_urlsafe
from uuid import UUID

import jwt
from pwdlib import PasswordHash
from pwdlib.exceptions import UnknownHashError

from app.core.config import get_settings
from app.schemas.auth import TokenPayload

password_hasher = PasswordHash.recommended()
DUMMY_PASSWORD_HASH = password_hasher.hash(token_urlsafe(32))


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    if len(password) > 128:
        password_hasher.verify("invalid-overlong-password", DUMMY_PASSWORD_HASH)
        return False
    try:
        return password_hasher.verify(password, password_hash)
    except UnknownHashError:
        password_hasher.verify(password, DUMMY_PASSWORD_HASH)
        return False


def create_access_token(user_id: UUID) -> str:
    settings = get_settings()
    expires = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    return jwt.encode(
        {"sub": str(user_id), "exp": expires},
        settings.jwt_secret_key.get_secret_value(),
        algorithm=settings.jwt_algorithm,
    )


def decode_access_token(token: str) -> TokenPayload:
    settings = get_settings()
    payload = jwt.decode(
        token,
        settings.jwt_secret_key.get_secret_value(),
        algorithms=[settings.jwt_algorithm],
        options={"require": ["sub", "exp"]},
    )
    return TokenPayload.model_validate(payload)
