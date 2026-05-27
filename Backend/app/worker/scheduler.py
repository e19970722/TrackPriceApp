import asyncio
from datetime import datetime, timezone

from app.database import AsyncSessionLocal
from app.repositories import tracker_repo
from app.worker.celery_app import celery


@celery.task(name="app.worker.scheduler.dispatch_due_scrapes")
def dispatch_due_scrapes() -> None:
    asyncio.run(_dispatch())


async def _dispatch() -> None:
    now = datetime.now(timezone.utc)
    async with AsyncSessionLocal() as db:
        due_trackers = await tracker_repo.get_due_trackers(db, now)

        for tracker in due_trackers:
            from app.worker.scraper import scrape_tracker  # noqa: PLC0415

            scrape_tracker.delay(str(tracker.id))

        await db.commit()
