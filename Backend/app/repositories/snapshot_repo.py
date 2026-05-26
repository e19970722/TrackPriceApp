"""SQLAlchemy queries for the PriceSnapshot model."""
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.price_snapshot import PriceSnapshot


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


async def create_snapshot(
    db: AsyncSession, tracker_id: UUID, price: Decimal, raw_text: str
) -> PriceSnapshot:
    snapshot = PriceSnapshot(tracker_id=tracker_id, price=price, raw_text=raw_text)
    db.add(snapshot)
    return snapshot
