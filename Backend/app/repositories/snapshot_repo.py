"""SQLAlchemy queries for the PriceSnapshot model."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import Row, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.price_snapshot import PriceSnapshot
from app.models.tracker import Tracker


async def get_snapshots_for_tracker(
    db: AsyncSession, tracker_id: UUID, limit: int = 100
) -> list[PriceSnapshot]:
    result = await db.execute(
        select(PriceSnapshot)
        .where(PriceSnapshot.tracker_id == tracker_id)
        .order_by(PriceSnapshot.scraped_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())


async def get_trend_rows_for_user(
    db: AsyncSession, user_id: UUID, since: datetime
) -> list[Row]:
    """Return one row per active tracker of *user_id* with snapshot aggregates.

    Each row carries (tracker_id, name, first_price, last_price, snapshot_count)
    computed over snapshots scraped at or after *since* — a single window-function
    query, no per-tracker round trips.
    """
    tracker_window = PriceSnapshot.tracker_id
    subq = (
        select(
            Tracker.id.label("tracker_id"),
            Tracker.name.label("name"),
            func.first_value(PriceSnapshot.price)
            .over(partition_by=tracker_window, order_by=PriceSnapshot.scraped_at.asc())
            .label("first_price"),
            func.first_value(PriceSnapshot.price)
            .over(partition_by=tracker_window, order_by=PriceSnapshot.scraped_at.desc())
            .label("last_price"),
            func.count().over(partition_by=tracker_window).label("snapshot_count"),
            func.row_number()
            .over(partition_by=tracker_window, order_by=PriceSnapshot.scraped_at.desc())
            .label("row_number"),
        )
        .join(PriceSnapshot, PriceSnapshot.tracker_id == Tracker.id)
        .where(
            Tracker.user_id == user_id,
            Tracker.status == "active",
            PriceSnapshot.scraped_at >= since,
        )
        .subquery()
    )
    result = await db.execute(
        select(
            subq.c.tracker_id,
            subq.c.name,
            subq.c.first_price,
            subq.c.last_price,
            subq.c.snapshot_count,
        ).where(subq.c.row_number == 1)
    )
    return list(result.all())


async def create_snapshot(
    db: AsyncSession, tracker_id: UUID, price: Decimal, raw_text: str
) -> PriceSnapshot:
    snapshot = PriceSnapshot(tracker_id=tracker_id, price=price, raw_text=raw_text)
    db.add(snapshot)
    return snapshot
