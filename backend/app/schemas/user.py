from uuid import UUID

from pydantic import EmailStr, Field, SecretStr, field_validator

from app.schemas.common import InputModel, TimestampRead


class UserCreate(InputModel):
    email: EmailStr
    password: SecretStr = Field(min_length=8, max_length=128)

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return value.strip().lower() if isinstance(value, str) else value


class UserRead(TimestampRead):
    id: UUID
    email: EmailStr
