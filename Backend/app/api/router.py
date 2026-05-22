from fastapi import APIRouter

from app.api import auth as auth_router_module
from app.api import dev

router = APIRouter()
router.include_router(dev.router)
router.include_router(auth_router_module.router)
