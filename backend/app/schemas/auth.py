from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class TokenResponse(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"


class TokenPayload(BaseModel):
    sub: UUID
    exp: int = Field(strict=True, gt=0)
