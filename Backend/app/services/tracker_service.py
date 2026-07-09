"""Business logic for tracker CRUD operations.

Wraps repository calls and enforces ownership checks.  Raises
domain-level ValueError so the API layer can convert to HTTP 404/403.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Sequence
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.tracker import Tracker
from app.models.user import User
from app.repositories import snapshot_repo, tracker_repo
from app.schemas.tracker import TrackerCreate, TrackerOut, TrackerTrendOut, TrackerUpdate

TREND_WINDOW_DAYS = 7
TREND_LIMIT = 10


def build_tracker_out(tracker: Tracker) -> dict:
    """Serialize *tracker* to a dict suitable for TrackerOut, adding next_checked_at."""
    d = TrackerOut.model_validate(tracker).model_dump()
    if tracker.last_checked_at is not None:
        d["next_checked_at"] = tracker.last_checked_at + timedelta(minutes=tracker.check_interval)
    return d


async def list_user_trackers(db: AsyncSession, user: User) -> list[dict]:
    trackers = await tracker_repo.get_trackers_for_user(db, user.id)
    return [build_tracker_out(t) for t in trackers]


async def create_user_tracker(db: AsyncSession, user: User, body: TrackerCreate) -> dict:
    tracker = await tracker_repo.create_tracker(db, user.id, body)
    return build_tracker_out(tracker)


async def get_user_tracker(db: AsyncSession, tracker_id: UUID, user: User) -> dict:
    tracker = await _require_owned(db, tracker_id, user.id)
    return build_tracker_out(tracker)


async def update_user_tracker(
    db: AsyncSession, tracker_id: UUID, user: User, body: TrackerUpdate
) -> dict:
    tracker = await _require_owned(db, tracker_id, user.id)
    updated = await tracker_repo.update_tracker(
        db, tracker, body.model_dump(exclude_none=True)
    )
    return build_tracker_out(updated)


async def delete_user_tracker(db: AsyncSession, tracker_id: UUID, user: User) -> None:
    tracker = await _require_owned(db, tracker_id, user.id)
    await tracker_repo.delete_tracker(db, tracker)


def compute_trends(rows: Sequence[Any], limit: int = TREND_LIMIT) -> list[TrackerTrendOut]:
    """Turn aggregated snapshot rows into sorted trend entries.

    Each row must expose tracker_id, name, first_price, last_price and
    snapshot_count.  Trackers with fewer than 2 snapshots in the window or a
    zero baseline price are skipped; results are sorted by delta_percent
    descending and capped at *limit*.
    """
    trends: list[TrackerTrendOut] = []
    for row in rows:
        if row.snapshot_count < 2:
            continue
        baseline = float(row.first_price)
        current = float(row.last_price)
        if baseline == 0:
            continue
        delta_percent = abs(current - baseline) / baseline * 100
        trends.append(
            TrackerTrendOut(
                tracker_id=row.tracker_id,
                name=row.name,
                direction="up" if current > baseline else "down",
                delta_percent=round(delta_percent, 2),
                current_price=current,
            )
        )
    trends.sort(key=lambda t: t.delta_percent, reverse=True)
    return trends[:limit]


async def get_user_tracker_trends(db: AsyncSession, user: User) -> list[TrackerTrendOut]:
    """Price movement over the trend window for the user's active trackers."""
    since = datetime.now(timezone.utc) - timedelta(days=TREND_WINDOW_DAYS)
    rows = await snapshot_repo.get_trend_rows_for_user(db, user.id, since)
    return compute_trends(rows)


async def get_owned_tracker_model(
    db: AsyncSession, tracker_id: UUID, user: User
) -> Tracker:
    """Return the raw ORM Tracker, raising ValueError if not found/owned."""
    return await _require_owned(db, tracker_id, user.id)


async def _require_owned(db: AsyncSession, tracker_id: UUID, user_id: UUID) -> Tracker:
    tracker = await tracker_repo.get_owned_tracker(db, tracker_id, user_id)
    if tracker is None:
        raise ValueError("Tracker not found")
    return tracker
