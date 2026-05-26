import asyncio
import logging
from datetime import datetime, timedelta, timezone

from app.database import AsyncSessionLocal
from app.models.tracker import Tracker
from app.push_sender import send_broken_alert
from app.repositories import tracker_repo, user_repo
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
        trackers = await tracker_repo.get_broken_candidates(db, cutoff)

        for tracker in trackers:
            tracker.status = "broken"
            if _should_notify(tracker, now):
                apns_token = await user_repo.get_apns_token(db, tracker.user_id)
                await send_broken_alert(apns_token or "", tracker)
                tracker.last_notified_at = now

        await db.commit()


def _should_notify(tracker: Tracker, now: datetime) -> bool:
    if tracker.last_notified_at is None:
        return True
    return (now - tracker.last_notified_at).total_seconds() >= 86400
