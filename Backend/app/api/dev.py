import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from jose import jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models.user import User

router = APIRouter(prefix="/dev", tags=["dev"])

DEV_USER_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")


def _guard():
    if settings.ENVIRONMENT == "production":
        raise HTTPException(status_code=404)


@router.post("/token")
async def dev_token(db: AsyncSession = Depends(get_db)):
    """Return a signed JWT for a dev user, creating the user if needed. Not available in production."""
    _guard()
    result = await db.execute(select(User).where(User.id == DEV_USER_ID))
    user = result.scalar_one_or_none()
    if user is None:
        user = User(
            id=DEV_USER_ID,
            auth_provider="dev",
            auth_provider_id="dev",
            email="dev@localhost",
        )
        db.add(user)
        await db.commit()

    payload = {
        "sub": str(DEV_USER_ID),
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(days=30),
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")
    return {"token": token, "user_id": str(DEV_USER_ID), "expires_in_days": 30}
