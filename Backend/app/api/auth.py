"""
Authentication endpoints for Apple Sign In and Google Sign In.

NOTE: Token claims are currently extracted without signature verification
(jwt.get_unverified_claims). This is intentional for the scaffold phase —
real signature verification against Apple JWKS / Google public certificates
will be added in a hardening pass once credentials are available.
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from jose import jwt
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import create_access_token
from app.database import get_db
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["auth"])


class AppleTokenRequest(BaseModel):
    token: str


class GoogleTokenRequest(BaseModel):
    token: str


class TokenResponse(BaseModel):
    token: str


async def _upsert_user(
    db: AsyncSession,
    auth_provider: str,
    auth_provider_id: str,
    email: Optional[str],
) -> User:
    result = await db.execute(
        select(User).where(
            User.auth_provider == auth_provider,
            User.auth_provider_id == auth_provider_id,
        )
    )
    user = result.scalar_one_or_none()
    if user is None:
        user = User(
            auth_provider=auth_provider,
            auth_provider_id=auth_provider_id,
            email=email,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
    return user


@router.post("/apple", response_model=TokenResponse)
async def apple_sign_in(
    body: AppleTokenRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    try:
        claims = jwt.get_unverified_claims(body.token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid Apple token"
        )

    apple_sub: Optional[str] = claims.get("sub")
    email: Optional[str] = claims.get("email")

    if not apple_sub:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apple token missing 'sub' claim",
        )

    user = await _upsert_user(db, "apple", apple_sub, email)
    return TokenResponse(token=create_access_token(user.id))


@router.post("/google", response_model=TokenResponse)
async def google_sign_in(
    body: GoogleTokenRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    try:
        claims = jwt.get_unverified_claims(body.token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid Google token"
        )

    google_sub: Optional[str] = claims.get("sub")
    email: Optional[str] = claims.get("email")

    if not google_sub:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google token missing 'sub' claim",
        )

    user = await _upsert_user(db, "google", google_sub, email)
    return TokenResponse(token=create_access_token(user.id))
