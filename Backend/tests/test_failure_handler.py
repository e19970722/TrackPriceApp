"""
Tests for the failure handler — no real DB required.
The DB session and _send_broken_notification are mocked.
"""
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.models.tracker import Tracker
from app.worker.failure_handler import _check_broken, _should_notify

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

NOW = datetime(2026, 5, 22, 12, 0, 0, tzinfo=timezone.utc)


def _make_tracker(
    *,
    failure_count: int,
    first_failure_at: datetime,
    status: str = "active",
    last_notified_at: Optional[datetime] = None,
) -> MagicMock:
    t = MagicMock(spec=Tracker)
    t.id = uuid.uuid4()
    t.user_id = uuid.uuid4()
    t.failure_count = failure_count
    t.first_failure_at = first_failure_at
    t.status = status
    t.last_notified_at = last_notified_at
    return t


def _mock_session(trackers: list) -> AsyncMock:
    session = AsyncMock()
    result = MagicMock()
    result.scalars.return_value.all.return_value = trackers
    session.execute.return_value = result
    session.commit = AsyncMock()
    return session


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_tracker_marked_broken_after_grace_period():
    tracker = _make_tracker(
        failure_count=10,
        first_failure_at=NOW - timedelta(days=4),
        status="active",
    )
    session = _mock_session([tracker])

    with (
        patch(
            "app.worker.failure_handler.AsyncSessionLocal",
            return_value=_async_ctx(session),
        ),
        patch(
            "app.worker.failure_handler._send_broken_notification",
            new_callable=AsyncMock,
        ) as mock_notify,
        patch("app.worker.failure_handler.datetime") as mock_dt,
    ):
        mock_dt.now.return_value = NOW
        mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)

        await _check_broken()

    assert tracker.status == "broken"
    mock_notify.assert_awaited_once_with(tracker)


@pytest.mark.asyncio
async def test_tracker_not_broken_within_grace_period():
    tracker = _make_tracker(
        failure_count=5,
        first_failure_at=NOW - timedelta(days=1),
        status="active",
    )
    session = _mock_session([])  # query returns empty — within grace period

    with (
        patch(
            "app.worker.failure_handler.AsyncSessionLocal",
            return_value=_async_ctx(session),
        ),
        patch(
            "app.worker.failure_handler._send_broken_notification",
            new_callable=AsyncMock,
        ) as mock_notify,
        patch("app.worker.failure_handler.datetime") as mock_dt,
    ):
        mock_dt.now.return_value = NOW
        mock_dt.side_effect = lambda *a, **kw: datetime(*a, **kw)

        await _check_broken()

    # Status was never changed because the DB query returned no trackers
    assert tracker.status == "active"
    mock_notify.assert_not_awaited()


@pytest.mark.asyncio
async def test_no_double_notify_within_24h():
    tracker = _make_tracker(
        failure_count=10,
        first_failure_at=NOW - timedelta(days=4),
        status="broken",
        last_notified_at=NOW - timedelta(hours=1),
    )
    # The query filters status != "broken", so this tracker won't be returned.
    # We directly test _should_notify to validate the throttle logic.
    assert _should_notify(tracker, NOW) is False


def test_should_notify_when_never_notified():
    tracker = _make_tracker(
        failure_count=1,
        first_failure_at=NOW - timedelta(days=4),
        last_notified_at=None,
    )
    assert _should_notify(tracker, NOW) is True


def test_should_notify_after_24h():
    tracker = _make_tracker(
        failure_count=1,
        first_failure_at=NOW - timedelta(days=4),
        last_notified_at=NOW - timedelta(hours=25),
    )
    assert _should_notify(tracker, NOW) is True


def test_should_not_notify_before_24h():
    tracker = _make_tracker(
        failure_count=1,
        first_failure_at=NOW - timedelta(days=4),
        last_notified_at=NOW - timedelta(hours=23),
    )
    assert _should_notify(tracker, NOW) is False


# ---------------------------------------------------------------------------
# Async context manager helper
# ---------------------------------------------------------------------------


class _async_ctx:
    """Wraps a mock session so it can be used as `async with AsyncSessionLocal() as db`."""

    def __init__(self, session: AsyncMock):
        self._session = session

    def __call__(self, *args, **kwargs):
        return self

    async def __aenter__(self) -> AsyncMock:
        return self._session

    async def __aexit__(self, *args) -> None:
        pass
