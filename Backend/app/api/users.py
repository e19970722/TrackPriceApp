from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_user
from app.database import get_db
from app.models.user import User
from app.repositories import user_repo
from app.schemas.user import UserOut, UserUpdate

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.patch("/me", response_model=UserOut)
async def patch_me(
    body: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    if body.apns_token is not None:
        current_user = await user_repo.update_apns_token(db, current_user, body.apns_token)
    if body.notification_preferences is not None:
        current_user = await user_repo.update_notification_preferences(
            db, current_user, body.notification_preferences
        )
    return current_user
