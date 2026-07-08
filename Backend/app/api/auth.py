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
    # Apple only exposes the user's name in the first-sign-in credential,
    # so the client forwards it explicitly.
    full_name: Optional[str] = None


class GoogleTokenRequest(BaseModel):
    token: str


class TokenResponse(BaseModel):
    token: str


async def _upsert_user(
    db: AsyncSession,
    auth_provider: str,
    auth_provider_id: str,
    email: Optional[str],
    display_name: Optional[str],
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
            display_name=display_name,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    # Backfill fields that were unavailable on earlier sign-ins.
    changed = False
    if user.email is None and email:
        user.email = email
        changed = True
    if user.display_name is None and display_name:
        user.display_name = display_name
        changed = True
    if changed:
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

    user = await _upsert_user(db, "apple", apple_sub, email, body.full_name)
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
    name: Optional[str] = claims.get("name")

    if not google_sub:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google token missing 'sub' claim",
        )

    user = await _upsert_user(db, "google", google_sub, email, name)
    return TokenResponse(token=create_access_token(user.id))
