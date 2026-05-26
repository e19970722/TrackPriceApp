import asyncio
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from app.database import AsyncSessionLocal
from app.models.tracker import Tracker
from app.worker.celery_app import celery


@celery.task(name="app.worker.scheduler.dispatch_due_scrapes")
def dispatch_due_scrapes() -> None:
    asyncio.run(_dispatch())


async def _dispatch() -> None:
    now = datetime.now(timezone.utc)
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Tracker).where(
                Tracker.status == "active",
                Tracker.last_checked_at + (Tracker.check_interval * timedelta(minutes=1)) <= now,
            )
        )
        due_trackers = result.scalars().all()

        for tracker in due_trackers:
            from app.worker.scraper import scrape_tracker  # noqa: PLC0415
            scrape_tracker.delay(str(tracker.id))

        await db.commit()
