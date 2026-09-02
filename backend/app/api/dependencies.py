from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jwt import InvalidTokenError
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.session import get_db
from app.models import User

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/token", auto_error=False
)
DbSession = Annotated[Session, Depends(get_db)]


def get_current_user(
    token: Annotated[str | None, Depends(oauth2_scheme)], db: DbSession
) -> User:
    unauthorized = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not token:
        raise unauthorized
    try:
        payload = decode_access_token(token)
    except (InvalidTokenError, ValueError, TypeError):
        raise unauthorized from None
    user = db.get(User, payload.sub)
    if user is None:
        raise unauthorized
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
