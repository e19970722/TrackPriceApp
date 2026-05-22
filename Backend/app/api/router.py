from fastapi import APIRouter

from app.api import dev

router = APIRouter()
router.include_router(dev.router)
