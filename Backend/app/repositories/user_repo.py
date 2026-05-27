"""SQLAlchemy queries for the User model."""
from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


async def get_apns_token(db: AsyncSession, user_id: UUID) -> str | None:
    result = await db.execute(select(User.apns_token).where(User.id == user_id))
    return result.scalar_one_or_none()


async def update_apns_token(db: AsyncSession, user: User, token: str) -> User:
    user.apns_token = token
    await db.commit()
    await db.refresh(user)
    return user
