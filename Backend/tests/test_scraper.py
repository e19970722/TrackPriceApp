"""
Unit tests for the scraping worker's _process_url_results helper.

No real database is needed — the DB session is fully mocked.
"""
import uuid
from decimal import Decimal
from typing import Optional
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.models.price_snapshot import PriceSnapshot
from app.models.tracker import Tracker
from app.models.url_job import UrlJob
from app.worker.scraper import _process_url_results


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

TARGET_URL = "https://example.com/product"


def _make_tracker(css_selector: str = "span.price") -> MagicMock:
    t = MagicMock(spec=Tracker)
    t.id = uuid.uuid4()
    t.url = TARGET_URL
    t.status = "active"
    t.css_selector = css_selector
    t.failure_count = 0
    t.first_failure_at = None
    t.last_price = None
    t.last_checked_at = None
    t.last_successful_fetch_at = None
    return t


def _make_session(trackers: list, url_job: Optional[MagicMock] = None) -> AsyncMock:
    """Return a mock async session that returns *trackers* and *url_job* on execute()."""
    session = AsyncMock()
    session.add = MagicMock()
    session.commit = AsyncMock()

    tracker_scalars = MagicMock()
    tracker_scalars.scalars.return_value.all.return_value = trackers

    url_job_result = MagicMock()
    url_job_result.scalar_one_or_none.return_value = url_job

    # First call → tracker query; second call → url_job query
    session.execute.side_effect = [tracker_scalars, url_job_result]
    return session


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_scrape_extracts_price():
    """A matching CSS selector yields a PriceSnapshot and updates tracker fields."""
    tracker = _make_tracker("span.price")
    url_job = MagicMock(spec=UrlJob)
    session = _make_session([tracker], url_job)

    html = "<html><body><span class='price'>$99.99</span></body></html>"

    with patch(
        "app.worker.scraper.AsyncSessionLocal",
        return_value=_async_context(session),
    ):
        await _process_url_results(TARGET_URL, html)

    # A PriceSnapshot must have been added
    session.add.assert_called_once()
    snapshot: PriceSnapshot = session.add.call_args[0][0]
    assert isinstance(snapshot, PriceSnapshot)
    assert snapshot.price == Decimal("99.99")
    assert snapshot.raw_text == "$99.99"

    # Tracker success fields
    assert tracker.last_price == Decimal("99.99")
    assert tracker.failure_count == 0
    assert tracker.first_failure_at is None
    assert tracker.last_checked_at is not None
    assert tracker.last_successful_fetch_at is not None

    # UrlJob updated
    assert url_job.fetch_status == "done"
    assert url_job.last_html_hash is not None

    session.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_scrape_selector_not_found_increments_failure():
    """When the CSS selector has no match, failure_count increments to 1."""
    tracker = _make_tracker("span.price")
    session = _make_session([tracker], url_job=None)

    html = "<html><body><p>No price here</p></body></html>"

    with patch(
        "app.worker.scraper.AsyncSessionLocal",
        return_value=_async_context(session),
    ):
        await _process_url_results(TARGET_URL, html)

    # No snapshot added
    session.add.assert_not_called()

    # Failure tracking
    assert tracker.failure_count == 1
    assert tracker.first_failure_at is not None
    assert tracker.last_checked_at is not None

    session.commit.assert_awaited_once()


# ---------------------------------------------------------------------------
# Async context-manager shim
# ---------------------------------------------------------------------------


class _AsyncContextManager:
    """Wraps a mock session so it can be used as `async with AsyncSessionLocal() as s`."""

    def __init__(self, session: AsyncMock) -> None:
        self._session = session

    async def __aenter__(self) -> AsyncMock:
        return self._session

    async def __aexit__(self, *args) -> None:
        pass


def _async_context(session: AsyncMock) -> _AsyncContextManager:
    return _AsyncContextManager(session)
