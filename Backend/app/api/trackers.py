from datetime import datetime, timedelta, timezone
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_user
from app.database import get_db
from app.models.price_snapshot import PriceSnapshot
from app.models.tracker import Tracker
from app.models.url_job import UrlJob
from app.models.user import User
from app.schemas.tracker import PriceSnapshotOut, TrackerCreate, TrackerOut, TrackerUpdate
from app.worker.scraper import scrape_url
from app.worker.sync_url_jobs import ensure_url_job

router = APIRouter(prefix="/trackers", tags=["trackers"])


async def _attach_next_check_at(trackers: list[Tracker], db: AsyncSession) -> list[dict]:
    urls = list({t.url for t in trackers})
    jobs_result = await db.execute(
        select(UrlJob.url, UrlJob.next_fetch_at).where(UrlJob.url.in_(urls))
    )
    next_check_by_url = {row.url: row.next_fetch_at for row in jobs_result.all()}
    out = []
    for t in trackers:
        d = TrackerOut.model_validate(t).model_dump()
        next_check = next_check_by_url.get(t.url)
        if next_check is None and t.last_checked_at is not None:
            next_check = t.last_checked_at + timedelta(minutes=t.check_interval)
        d["next_check_at"] = next_check
        out.append(d)
    return out


@router.get("", response_model=List[TrackerOut])
async def list_trackers(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[TrackerOut]:
    result = await db.execute(
        select(Tracker).where(Tracker.user_id == current_user.id)
    )
    trackers = list(result.scalars().all())
    return await _attach_next_check_at(trackers, db)


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
        interactions=body.interactions,
        currency_symbol=body.currency_symbol,
        target_price=body.target_price,
        target_direction=body.target_direction,
        last_price=body.confirmed_price,
        last_checked_at=datetime.now(timezone.utc),
    )
    db.add(tracker)
    await db.commit()
    await db.refresh(tracker)
    try:
        ensure_url_job.delay(tracker.url, tracker.check_interval)
    except Exception:
        pass  # Redis not available — worker will pick up job when it starts
    return tracker


@router.get("/{tracker_id}", response_model=TrackerOut)
async def get_tracker(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    tracker = await _get_owned_tracker(tracker_id, current_user, db)
    return (await _attach_next_check_at([tracker], db))[0]


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


@router.get("/{tracker_id}/price", response_model=TrackerOut)
async def get_current_price(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    tracker = await _get_owned_tracker(tracker_id, current_user, db)
    try:
        scrape_url.delay(tracker.url)
    except Exception:
        pass  # Redis not available in dev — scrape runs via scheduled worker
    return (await _attach_next_check_at([tracker], db))[0]


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
