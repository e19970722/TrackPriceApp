import asyncio
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from app.database import AsyncSessionLocal
from app.models.url_job import UrlJob
from app.worker.celery_app import celery


@celery.task(name="app.worker.sync_url_jobs.ensure_url_job")
def ensure_url_job(url: str, check_interval: str) -> None:
    asyncio.run(_ensure(url, check_interval))


async def _ensure(url: str, check_interval: str) -> None:
    now = datetime.now(timezone.utc)
    delta = timedelta(hours=1 if check_interval == "hourly" else 24)

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(UrlJob).where(UrlJob.url == url))
        job = result.scalar_one_or_none()

        if job is None:
            job = UrlJob(
                url=url,
                next_fetch_at=now,
                fetch_status="pending",
            )
            db.add(job)
        else:
            candidate = now + delta
            if job.next_fetch_at is None or job.next_fetch_at > candidate:
                job.next_fetch_at = candidate

        await db.commit()
