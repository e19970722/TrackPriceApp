import asyncio
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from app.database import AsyncSessionLocal
from app.models.tracker import Tracker
from app.worker.celery_app import celery

logger = logging.getLogger(__name__)

FAILURE_GRACE_PERIOD_DAYS = 3


@celery.task(name="app.worker.failure_handler.check_broken_trackers")
def check_broken_trackers() -> None:
    asyncio.run(_check_broken())


async def _check_broken() -> None:
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=FAILURE_GRACE_PERIOD_DAYS)

    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Tracker).where(
                Tracker.failure_count > 0,
                Tracker.first_failure_at <= cutoff,
                Tracker.status != "broken",
            )
        )
        trackers = result.scalars().all()

        for tracker in trackers:
            tracker.status = "broken"
            if _should_notify(tracker, now):
                await _send_broken_notification(tracker)
                tracker.last_notified_at = now

        await db.commit()


def _should_notify(tracker: Tracker, now: datetime) -> bool:
    if tracker.last_notified_at is None:
        return True
    return (now - tracker.last_notified_at).total_seconds() >= 86400


async def _send_broken_notification(tracker: Tracker) -> None:
    logger.warning(
        "Tracker %s broken — user %s needs to re-select element",
        tracker.id,
        tracker.user_id,
    )
