import asyncio
from datetime import datetime, timezone

from sqlalchemy import select

from app.database import AsyncSessionLocal
from app.models.url_job import UrlJob
from app.worker.celery_app import celery


@celery.task(name="app.worker.scheduler.dispatch_due_scrapes")
def dispatch_due_scrapes() -> None:
    asyncio.run(_dispatch())


async def _dispatch() -> None:
    now = datetime.now(timezone.utc)
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(UrlJob).where(
                UrlJob.next_fetch_at <= now,
                UrlJob.fetch_status != "in_progress",
            )
        )
        due_jobs = result.scalars().all()

        for job in due_jobs:
            job.fetch_status = "in_progress"
            from app.worker.scraper import scrape_url  # noqa: PLC0415
            scrape_url.delay(job.url)

        await db.commit()
