from fastapi import APIRouter, Response

from app.api.dependencies import DbSession
from app.api.transactions import commit_or_conflict
from app.core.security import create_access_token
from app.schemas.auth import TokenResponse
from app.schemas.common import InputModel
from app.services.demo import get_demo_user

router = APIRouter(prefix="/api/v1/dev", tags=["development"])


class DemoRequest(InputModel):
    pass


@router.post("/demo-session", response_model=TokenResponse)
def demo_session(db: DbSession, response: Response, payload: DemoRequest | None = None) -> TokenResponse:
    user = get_demo_user(db)
    commit_or_conflict(db)
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    return TokenResponse(access_token=create_access_token(user.id))
