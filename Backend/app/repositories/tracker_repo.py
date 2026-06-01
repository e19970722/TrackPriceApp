"""SQLAlchemy queries for the Tracker model."""
from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.tracker import Tracker
from app.schemas.tracker import TrackerCreate


async def get_trackers_for_user(db: AsyncSession, user_id: UUID) -> list[Tracker]:
    result = await db.execute(select(Tracker).where(Tracker.user_id == user_id))
    return list(result.scalars().all())


async def get_tracker_by_id(db: AsyncSession, tracker_id: UUID) -> Tracker | None:
    result = await db.execute(select(Tracker).where(Tracker.id == tracker_id))
    return result.scalar_one_or_none()


async def get_owned_tracker(
    db: AsyncSession, tracker_id: UUID, user_id: UUID
) -> Tracker | None:
    result = await db.execute(
        select(Tracker).where(Tracker.id == tracker_id, Tracker.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create_tracker(db: AsyncSession, user_id: UUID, body: TrackerCreate) -> Tracker:
    tracker = Tracker(
        user_id=user_id,
        url=body.url,
        name=body.name,
        interactions=body.interactions,
        currency_symbol=body.currency_symbol,
        target_price=body.target_price,
        target_direction=body.target_direction,
        last_price=body.confirmed_price,
        last_checked_at=datetime.now(timezone.utc),
        item_image_url=body.item_image_url,
    )
    db.add(tracker)
    await db.commit()
    await db.refresh(tracker)
    return tracker


async def update_tracker(
    db: AsyncSession, tracker: Tracker, fields: dict
) -> Tracker:
    for field, value in fields.items():
        setattr(tracker, field, value)
    await db.commit()
    await db.refresh(tracker)
    return tracker


async def delete_tracker(db: AsyncSession, tracker: Tracker) -> None:
    await db.delete(tracker)
    await db.commit()


async def get_due_trackers(db: AsyncSession, now: datetime) -> list[Tracker]:
    """Return active trackers whose next check time has passed."""
    from datetime import timedelta

    result = await db.execute(
        select(Tracker).where(
            Tracker.status == "active",
            Tracker.last_checked_at + (Tracker.check_interval * timedelta(minutes=1)) <= now,
        )
    )
    return list(result.scalars().all())


async def get_broken_candidates(db: AsyncSession, cutoff: datetime) -> list[Tracker]:
    """Return trackers that have been failing since before *cutoff* and are not yet 'broken'."""
    result = await db.execute(
        select(Tracker).where(
            Tracker.failure_count > 0,
            Tracker.first_failure_at <= cutoff,
            Tracker.status != "broken",
        )
    )
    return list(result.scalars().all())
