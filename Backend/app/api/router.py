from fastapi import APIRouter

from app.api import auth as auth_router_module
from app.api import dev
from app.api import trackers as trackers_router_module

router = APIRouter()
router.include_router(dev.router)
router.include_router(auth_router_module.router)
router.include_router(trackers_router_module.router)
