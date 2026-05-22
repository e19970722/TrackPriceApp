from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_user
from app.database import get_db
from app.models.price_snapshot import PriceSnapshot
from app.models.tracker import Tracker
from app.models.user import User
from app.schemas.tracker import PriceSnapshotOut, TrackerCreate, TrackerOut, TrackerUpdate
from app.worker.sync_url_jobs import ensure_url_job

router = APIRouter(prefix="/trackers", tags=["trackers"])


@router.get("", response_model=List[TrackerOut])
async def list_trackers(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[TrackerOut]:
    result = await db.execute(
        select(Tracker).where(Tracker.user_id == current_user.id)
    )
    return list(result.scalars().all())


@router.post("", response_model=TrackerOut, status_code=status.HTTP_201_CREATED)
async def create_tracker(
    body: TrackerCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    tracker = Tracker(
        user_id=current_user.id,
        url=body.url,
        name=body.name,
        css_selector=body.css_selector,
        xpath=body.xpath,
        currency_symbol=body.currency_symbol,
        target_price=body.target_price,
        target_direction=body.target_direction,
        last_price=body.confirmed_price,
    )
    db.add(tracker)
    await db.commit()
    await db.refresh(tracker)
    ensure_url_job.delay(tracker.url, tracker.check_interval)
    return tracker


@router.get("/{tracker_id}", response_model=TrackerOut)
async def get_tracker(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    tracker = await _get_owned_tracker(tracker_id, current_user, db)
    return tracker


@router.patch("/{tracker_id}", response_model=TrackerOut)
async def update_tracker(
    tracker_id: UUID,
    body: TrackerUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    tracker = await _get_owned_tracker(tracker_id, current_user, db)
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(tracker, field, value)
    await db.commit()
    await db.refresh(tracker)
    return tracker


@router.delete("/{tracker_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tracker(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    tracker = await _get_owned_tracker(tracker_id, current_user, db)
    await db.delete(tracker)
    await db.commit()


@router.get("/{tracker_id}/history", response_model=List[PriceSnapshotOut])
async def get_price_history(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[PriceSnapshotOut]:
    await _get_owned_tracker(tracker_id, current_user, db)
    result = await db.execute(
        select(PriceSnapshot)
        .where(PriceSnapshot.tracker_id == tracker_id)
        .order_by(PriceSnapshot.scraped_at.desc())
        .limit(100)
    )
    return list(result.scalars().all())


async def _get_owned_tracker(
    tracker_id: UUID,
    user: User,
    db: AsyncSession,
) -> Tracker:
    result = await db.execute(
        select(Tracker).where(Tracker.id == tracker_id, Tracker.user_id == user.id)
    )
    tracker = result.scalar_one_or_none()
    if tracker is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tracker not found")
    return tracker
