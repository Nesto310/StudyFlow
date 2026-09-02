from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select

from app.api.dependencies import DbSession
from app.api.transactions import commit_or_conflict
from app.core.security import (
    DUMMY_PASSWORD_HASH,
    create_access_token,
    hash_password,
    verify_password,
)
from app.models import User
from app.schemas.auth import TokenResponse
from app.schemas.user import UserCreate, UserRead

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserRead, status_code=201)
def register(payload: UserCreate, db: DbSession) -> User:
    if db.scalar(select(User.id).where(User.email == payload.email)) is not None:
        raise HTTPException(status_code=409, detail="Email already registered")
    user = User(
        email=str(payload.email),
        password_hash=hash_password(payload.password.get_secret_value()),
    )
    db.add(user)
    commit_or_conflict(db, "Email already registered")
    db.refresh(user)
    return user


@router.post("/token", response_model=TokenResponse)
def login(
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: DbSession,
    response: Response,
) -> TokenResponse:
    email = form.username.strip().lower()
    user = db.scalars(select(User).where(User.email == email)).one_or_none()
    stored_hash = user.password_hash if user is not None else DUMMY_PASSWORD_HASH
    password_valid = verify_password(form.password, stored_hash)
    if user is None or not password_valid:
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    return TokenResponse(access_token=create_access_token(user.id))
