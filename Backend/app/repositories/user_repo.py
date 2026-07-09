"""SQLAlchemy queries for the User model."""
from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user import NotificationPreferencesUpdate

# Preference field on the schema -> column on the users table.
_PREF_COLUMNS = {
    "price_drops": "notify_price_drops",
    "expiring_soon": "notify_expiring_soon",
    "running_low": "notify_running_low",
    "weekly_digest": "notify_weekly_digest",
    "expiring_soon_days_before": "expiring_soon_days_before",
    "running_low_threshold": "running_low_threshold",
}


async def get_apns_token(db: AsyncSession, user_id: UUID) -> str | None:
    result = await db.execute(select(User.apns_token).where(User.id == user_id))
    return result.scalar_one_or_none()


async def get_push_info(
    db: AsyncSession, user_id: UUID
) -> tuple[str | None, bool, bool] | None:
    """Return ``(apns_token, notify_price_drops, notify_expiring_soon)`` in one query."""
    result = await db.execute(
        select(User.apns_token, User.notify_price_drops, User.notify_expiring_soon).where(
            User.id == user_id
        )
    )
    row = result.one_or_none()
    if row is None:
        return None
    return (row[0], row[1], row[2])


async def update_apns_token(db: AsyncSession, user: User, token: str) -> User:
    user.apns_token = token
    await db.commit()
    await db.refresh(user)
    return user


async def update_notification_preferences(
    db: AsyncSession, user: User, prefs: NotificationPreferencesUpdate
) -> User:
    """Apply only the preference fields that were provided (merge semantics)."""
    for pref_field, column in _PREF_COLUMNS.items():
        value = getattr(prefs, pref_field)
        if value is not None:
            setattr(user, column, value)
    await db.commit()
    await db.refresh(user)
    return user
