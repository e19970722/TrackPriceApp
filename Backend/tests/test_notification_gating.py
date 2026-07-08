"""
Tests for per-user notification-preference gating of push dispatch.

- Price alerts are skipped when `notify_price_drops` is false, and
  `last_notified_at` is NOT updated so re-enabling resumes alerts.
- Item expiry reminders (advance and on-day) are skipped when
  `notify_expiring_soon` is false.

DB, Redis, and push senders are mocked — no real infrastructure required.
"""
from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.models.item import Item
from app.models.tracker import Tracker
from app.services.price_service import process_tracker_scrape
from app.worker.item_reminder import _check_reminders

TODAY = date(2026, 6, 2)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


class _async_ctx:
    """Wraps a mock session for use as `async with AsyncSessionLocal() as db`."""

    def __init__(self, session: AsyncMock) -> None:
        self._session = session

    def __call__(self, *args, **kwargs) -> "_async_ctx":
        return self

    async def __aenter__(self) -> AsyncMock:
        return self._session

    async def __aexit__(self, *args) -> None:
        pass


def _fake_tracker() -> MagicMock:
    t = MagicMock(spec=Tracker)
    t.id = uuid.uuid4()
    t.user_id = uuid.uuid4()
    t.url = "https://example.com/product"
    t.interactions = []
    t.item_name = "Widget"
    t.item_image_url = "https://example.com/img.png"
    t.last_notified_at = None
    t.last_notified_price = None
    t.failure_count = 0
    t.first_failure_at = None
    return t


def _fake_item(*, remind_on_day: bool = False, best_before: date = date(2026, 6, 5)) -> MagicMock:
    i = MagicMock(spec=Item)
    i.id = uuid.uuid4()
    i.user_id = uuid.uuid4()
    i.name = "Milk"
    i.best_before_date = best_before
    i.remind_days_before = 3
    i.remind_on_day = remind_on_day
    return i


async def _run_price_scrape(tracker: MagicMock, push_info: tuple) -> AsyncMock:
    """Run process_tracker_scrape with everything mocked; return the send mock."""
    session = AsyncMock()

    with (
        patch(
            "app.services.price_service.AsyncSessionLocal",
            new=_async_ctx(session),
        ),
        patch(
            "app.services.price_service.scrape_page",
            new=AsyncMock(return_value=("$10.00", Decimal("10.00"), None, None)),
        ),
        patch(
            "app.services.price_service.tracker_repo.get_tracker_by_id",
            new=AsyncMock(return_value=tracker),
        ),
        patch(
            "app.services.price_service.snapshot_repo.create_snapshot",
            new=AsyncMock(),
        ),
        patch("app.services.price_service.should_alert", return_value=True),
        patch(
            "app.services.price_service.user_repo.get_push_info",
            new=AsyncMock(return_value=push_info),
        ),
        patch("app.push_sender.send_price_alert", new_callable=AsyncMock) as mock_send,
    ):
        await process_tracker_scrape(tracker.id)

    return mock_send


# ---------------------------------------------------------------------------
# Price alert gating
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_price_alert_skipped_when_price_drops_disabled() -> None:
    tracker = _fake_tracker()

    mock_send = await _run_price_scrape(tracker, ("device-token", False, True))

    mock_send.assert_not_awaited()
    # last_notified_at untouched → re-enabling the preference resumes alerts
    assert tracker.last_notified_at is None
    assert tracker.last_notified_price is None


@pytest.mark.asyncio
async def test_price_alert_sent_when_price_drops_enabled() -> None:
    tracker = _fake_tracker()

    mock_send = await _run_price_scrape(tracker, ("device-token", True, True))

    mock_send.assert_awaited_once()
    assert tracker.last_notified_at is not None
    assert tracker.last_notified_price == 10.0


# ---------------------------------------------------------------------------
# Item expiry reminder gating
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_reminders_skipped_when_expiring_soon_disabled() -> None:
    """Both advance and on-day reminders are skipped when the pref is off."""
    advance_item = _fake_item(best_before=date(2026, 6, 5))
    today_item = _fake_item(remind_on_day=True, best_before=TODAY)

    push_info_off = MagicMock()
    push_info_off.one_or_none.return_value = ("device-token", True, False)

    session = AsyncMock()
    session.execute.side_effect = [
        MagicMock(**{"scalars.return_value.all.return_value": [advance_item]}),
        push_info_off,  # advance item's push info (expiring_soon off)
        MagicMock(**{"scalars.return_value.all.return_value": [today_item]}),
        push_info_off,  # today item's push info (expiring_soon off)
    ]

    with (
        patch(
            "app.worker.item_reminder.AsyncSessionLocal",
            new=_async_ctx(session),
        ),
        patch("app.worker.item_reminder.datetime") as mock_dt,
        patch("app.worker.item_reminder._get_redis", return_value=None),
        patch(
            "app.push_sender.send_item_reminder", new_callable=AsyncMock
        ) as mock_advance_send,
        patch(
            "app.push_sender.send_item_expiring_today", new_callable=AsyncMock
        ) as mock_today_send,
    ):
        mock_now = MagicMock()
        mock_now.date.return_value = TODAY
        mock_dt.now.return_value = mock_now

        await _check_reminders()

    mock_advance_send.assert_not_awaited()
    mock_today_send.assert_not_awaited()
