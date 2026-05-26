"""Business logic for tracker CRUD operations.

Wraps repository calls and enforces ownership checks.  Raises
domain-level ValueError so the API layer can convert to HTTP 404/403.
"""
from datetime import timedelta
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.tracker import Tracker
from app.models.user import User
from app.repositories import tracker_repo
from app.schemas.tracker import TrackerCreate, TrackerOut, TrackerUpdate


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
