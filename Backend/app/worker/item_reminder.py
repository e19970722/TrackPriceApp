"""Celery task: daily check for expiring items and push notifications.

Throttle: max 1 push per item per day using a Redis key
``item_reminder:{item_id}:{YYYY-MM-DD}``.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import date, datetime, timezone

from app.database import AsyncSessionLocal
from app.repositories import item_repo, user_repo
from app.worker.celery_app import celery

logger = logging.getLogger(__name__)

_REDIS_KEY_TTL_SECONDS = 86400  # 24 hours


@celery.task(name="app.worker.item_reminder.check_item_reminders")
def check_item_reminders() -> None:
    asyncio.run(_check_reminders())


async def _check_reminders() -> None:
    today = datetime.now(timezone.utc).date()
    redis_client = _get_redis()

    async with AsyncSessionLocal() as db:
        # Advance reminders: best_before_date - remind_days_before == today
        advance_items = await item_repo.get_items_due_for_reminder(db, today)
        for item in advance_items:
            if _throttle_ok(redis_client, item.id, today, suffix="advance"):
                apns_token = await _pushable_token(db, item.user_id)
                if apns_token:
                    days_left = (item.best_before_date - today).days
                    from app.push_sender import send_item_reminder  # noqa: PLC0415

                    await send_item_reminder(apns_token, item, days_left)
                    _mark_throttled(redis_client, item.id, today, suffix="advance")

        # On-day reminders: best_before_date == today and remind_on_day=true
        today_items = await item_repo.get_items_expiring_today(db, today)
        for item in today_items:
            if _throttle_ok(redis_client, item.id, today, suffix="today"):
                apns_token = await _pushable_token(db, item.user_id)
                if apns_token:
                    from app.push_sender import send_item_expiring_today  # noqa: PLC0415

                    await send_item_expiring_today(apns_token, item)
                    _mark_throttled(redis_client, item.id, today, suffix="today")


async def _pushable_token(db, user_id) -> str | None:
    """Return the user's APNs token, or None when the user has expiring-soon
    notifications disabled (or has no token)."""
    push_info = await user_repo.get_push_info(db, user_id)
    if push_info is None:
        return None
    apns_token, _notify_price_drops, notify_expiring_soon = push_info
    if not notify_expiring_soon:
        return None
    return apns_token


def _throttle_key(item_id, today: date, suffix: str) -> str:
    return f"item_reminder:{item_id}:{today.isoformat()}:{suffix}"


def _throttle_ok(redis_client, item_id, today: date, suffix: str) -> bool:
    if redis_client is None:
        return True
    key = _throttle_key(item_id, today, suffix)
    return redis_client.get(key) is None


def _mark_throttled(redis_client, item_id, today: date, suffix: str) -> None:
    if redis_client is None:
        return
    key = _throttle_key(item_id, today, suffix)
    redis_client.set(key, "1", ex=_REDIS_KEY_TTL_SECONDS)


def _get_redis():
    """Return a synchronous Redis client (redis-py), or None if unavailable."""
    try:
        import redis  # type: ignore[import-untyped]

        from app.config import settings

        return redis.from_url(settings.REDIS_URL, decode_responses=True)
    except Exception:  # noqa: BLE001
        logger.warning("Redis unavailable — item reminder throttle disabled")
        return None
