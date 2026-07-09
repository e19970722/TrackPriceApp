from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_user
from app.database import get_db
from app.models.user import User
from app.repositories import snapshot_repo
from app.schemas.tracker import (
    PriceSnapshotOut,
    TrackerCreate,
    TrackerOut,
    TrackerTrendOut,
    TrackerUpdate,
)
from app.services import tracker_service

router = APIRouter(prefix="/trackers", tags=["trackers"])


@router.get("", response_model=List[TrackerOut])
async def list_trackers(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[TrackerOut]:
    return await tracker_service.list_user_trackers(db, current_user)  # type: ignore[return-value]


@router.post("", response_model=TrackerOut, status_code=status.HTTP_201_CREATED)
async def create_tracker(
    body: TrackerCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    return await tracker_service.create_user_tracker(db, current_user, body)  # type: ignore[return-value]


# NOTE: must stay registered before the dynamic "/{tracker_id}" routes below,
# otherwise FastAPI tries to parse "trends" as a tracker UUID (422).
@router.get("/trends", response_model=List[TrackerTrendOut])
async def get_tracker_trends(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[TrackerTrendOut]:
    """GLOBAL trending across all users (incl. seeded defaults), not just this user."""
    return await tracker_service.get_global_tracker_trends(db, current_user)


@router.post(
    "/trends/{tracker_id}/track",
    response_model=TrackerOut,
    status_code=status.HTTP_201_CREATED,
)
async def track_trend_item(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    """Clone a global/seed trend tracker into a new tracker owned by the caller."""
    try:
        return await tracker_service.clone_trend_tracker(db, tracker_id, current_user)  # type: ignore[return-value]
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Trend tracker not found"
        )


@router.get("/{tracker_id}", response_model=TrackerOut)
async def get_tracker(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    return await _get_or_404(db, tracker_id, current_user)


@router.patch("/{tracker_id}", response_model=TrackerOut)
async def update_tracker(
    tracker_id: UUID,
    body: TrackerUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    try:
        return await tracker_service.update_user_tracker(db, tracker_id, current_user, body)  # type: ignore[return-value]
    except ValueError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tracker not found")


@router.delete("/{tracker_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tracker(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    try:
        await tracker_service.delete_user_tracker(db, tracker_id, current_user)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tracker not found")


@router.get("/{tracker_id}/price", response_model=TrackerOut)
async def get_current_price(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TrackerOut:
    result = await _get_or_404(db, tracker_id, current_user)
    try:
        from app.worker.scraper import scrape_tracker  # noqa: PLC0415

        scrape_tracker.delay(str(tracker_id))
    except Exception:
        pass
    return result


@router.get("/{tracker_id}/history", response_model=List[PriceSnapshotOut])
async def get_price_history(
    tracker_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[PriceSnapshotOut]:
    await _get_or_404(db, tracker_id, current_user)
    snapshots = await snapshot_repo.get_snapshots_for_tracker(db, tracker_id)
    return snapshots  # type: ignore[return-value]


async def _get_or_404(db: AsyncSession, tracker_id: UUID, user: User) -> TrackerOut:
    try:
        return await tracker_service.get_user_tracker(db, tracker_id, user)  # type: ignore[return-value]
    except ValueError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tracker not found")
