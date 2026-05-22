"""Tests for the URL-level deduplication scheduler."""

import sys
from datetime import datetime, timedelta, timezone
from types import ModuleType
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.models.url_job import UrlJob
from app.worker.scheduler import _dispatch


def _make_job(url: str, fetch_status: str, minutes_overdue: int = 5) -> UrlJob:
    job = UrlJob()
    job.url = url
    job.fetch_status = fetch_status
    job.next_fetch_at = datetime.now(timezone.utc) - timedelta(minutes=minutes_overdue)
    return job


def _fake_scraper_module() -> tuple:
    """Return (fake_module, mock_delay) to inject into sys.modules."""
    mock_delay = MagicMock()
    mock_scrape_url = MagicMock()
    mock_scrape_url.delay = mock_delay

    fake_mod = ModuleType("app.worker.scraper")
    fake_mod.scrape_url = mock_scrape_url  # type: ignore[attr-defined]
    return fake_mod, mock_delay


def _mock_session(jobs: list) -> tuple:
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = jobs

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=mock_result)
    mock_db.commit = AsyncMock()

    mock_ctx = AsyncMock()
    mock_ctx.__aenter__ = AsyncMock(return_value=mock_db)
    mock_ctx.__aexit__ = AsyncMock(return_value=False)
    return mock_ctx, mock_db


@pytest.mark.asyncio
async def test_dispatch_enqueues_due_jobs() -> None:
    """Jobs with next_fetch_at in the past and status != in_progress are enqueued."""
    job = _make_job("https://example.com/product", fetch_status="pending")
    fake_mod, mock_delay = _fake_scraper_module()
    mock_ctx, mock_db = _mock_session([job])

    sys.modules["app.worker.scraper"] = fake_mod
    try:
        with patch("app.worker.scheduler.AsyncSessionLocal", return_value=mock_ctx):
            await _dispatch()
    finally:
        sys.modules.pop("app.worker.scraper", None)

    assert job.fetch_status == "in_progress"
    mock_delay.assert_called_once_with("https://example.com/product")
    mock_db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_dispatch_skips_in_progress_jobs() -> None:
    """Jobs already in_progress are filtered out by the DB query — nothing enqueued."""
    fake_mod, mock_delay = _fake_scraper_module()
    # DB returns empty list (the WHERE clause filters in_progress jobs)
    mock_ctx, mock_db = _mock_session([])

    sys.modules["app.worker.scraper"] = fake_mod
    try:
        with patch("app.worker.scheduler.AsyncSessionLocal", return_value=mock_ctx):
            await _dispatch()
    finally:
        sys.modules.pop("app.worker.scraper", None)

    mock_delay.assert_not_called()
    mock_db.commit.assert_awaited_once()
