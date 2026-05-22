from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException
from jose import jwt

from app.config import settings

router = APIRouter(prefix="/dev", tags=["dev"])

DEV_USER_ID = "00000000-0000-0000-0000-000000000001"


def _guard():
    if settings.ENVIRONMENT == "production":
        raise HTTPException(status_code=404)


@router.post("/token")
async def dev_token():
    """Return a signed JWT for a dev user. Not available in production."""
    _guard()
    payload = {
        "sub": DEV_USER_ID,
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(days=30),
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")
    return {"token": token, "user_id": DEV_USER_ID, "expires_in_days": 30}
