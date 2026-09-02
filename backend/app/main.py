from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.api.router import api_router
from app.core.config import Settings, get_settings


async def validation_error(_request: Request, exc: RequestValidationError) -> JSONResponse:
    # Do not echo submitted passwords or tokens in validation responses.
    errors = [
        {"loc": error["loc"], "msg": error["msg"], "type": error["type"]}
        for error in exc.errors()
    ]
    return JSONResponse(status_code=422, content={"detail": errors})


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    application = FastAPI(title=settings.app_name)
    application.include_router(api_router)
    application.add_exception_handler(RequestValidationError, validation_error)
    if settings.app_env == "development":
        from app.api.routes.dev import router as dev_router

        application.include_router(dev_router)
    return application


app = create_app()
