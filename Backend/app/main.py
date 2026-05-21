from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.router import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="TrackPriceApp", lifespan=lifespan)
app.include_router(router)


@app.get("/health")
async def health():
    return {"status": "ok"}
