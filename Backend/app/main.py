import traceback
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.router import router
from app.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="TrackPriceApp", lifespan=lifespan)
app.include_router(router)


@app.exception_handler(Exception)
async def debug_exception_handler(request: Request, exc: Exception):
    if settings.ENVIRONMENT != "production":
        return JSONResponse(
            status_code=500,
            content={"detail": str(exc), "traceback": traceback.format_exc()},
        )
    return JSONResponse(status_code=500, content={"detail": "Internal Server Error"})


@app.get("/health")
async def health():
    return {"status": "ok"}
