"""
Unit tests for the scraping worker's _process_tracker helper.

Playwright interaction replay is mocked — only the DB update logic is tested.
"""
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.models.price_snapshot import PriceSnapshot
from app.models.tracker import Tracker
from app.worker.scraper import _process_tracker


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

TARGET_URL = "https://example.com/product"
NOW = datetime.now(tz=timezone.utc)

INTERACTIONS = [
    {"type": "click", "locator": "[data-sku='blue']"},
    {"type": "click", "locator": "#price-block", "role": "price",
     "rawText": "$99.99", "currentPrice": 99.99, "currencySymbol": "$"},
]


def _make_tracker() -> MagicMock:
    t = MagicMock(spec=Tracker)
    t.id = uuid.uuid4()
    t.user_id = uuid.uuid4()
    t.url = TARGET_URL
    t.status = "active"
    t.interactions = INTERACTIONS
    t.failure_count = 0
    t.first_failure_at = None
    t.last_price = None
    t.last_checked_at = None
    t.last_successful_fetch_at = None
    t.last_notified_at = None
    t.last_notified_price = None
    t.target_price = 80.0
    t.target_direction = "below"
    return t


def _make_session() -> AsyncMock:
    session = AsyncMock()
    session.add = MagicMock()
    session.commit = AsyncMock()
    device_token_result = MagicMock()
    device_token_result.scalar_one_or_none.return_value = None
    session.execute.return_value = device_token_result
    return session


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_process_tracker_records_snapshot():
    """A successful scrape creates a PriceSnapshot and updates tracker fields."""
    tracker = _make_tracker()
    session = _make_session()

    with patch("app.worker.scraper._scrape_tracker", new=AsyncMock(return_value=("$99.99", Decimal("99.99")))):
        await _process_tracker(tracker, NOW, session)

    session.add.assert_called_once()
    snapshot: PriceSnapshot = session.add.call_args[0][0]
    assert isinstance(snapshot, PriceSnapshot)
    assert snapshot.price == Decimal("99.99")
    assert snapshot.raw_text == "$99.99"

    assert tracker.last_price == Decimal("99.99")
    assert tracker.failure_count == 0
    assert tracker.first_failure_at is None
    assert tracker.last_checked_at == NOW
    assert tracker.last_successful_fetch_at == NOW


@pytest.mark.asyncio
async def test_process_tracker_failure_increments_count():
    """When _scrape_tracker returns None, failure_count increments."""
    tracker = _make_tracker()
    session = _make_session()

    with patch("app.worker.scraper._scrape_tracker", new=AsyncMock(return_value=(None, None))):
        await _process_tracker(tracker, NOW, session)

    session.add.assert_not_called()
    assert tracker.failure_count == 1
    assert tracker.first_failure_at == NOW
    assert tracker.last_checked_at == NOW


@pytest.mark.asyncio
async def test_process_tracker_existing_failure_increments():
    """failure_count increments on repeated failures without resetting first_failure_at."""
    tracker = _make_tracker()
    tracker.failure_count = 2
    tracker.first_failure_at = NOW
    session = _make_session()

    with patch("app.worker.scraper._scrape_tracker", new=AsyncMock(return_value=(None, None))):
        await _process_tracker(tracker, NOW, session)

    assert tracker.failure_count == 3
    assert tracker.first_failure_at == NOW  # unchanged
