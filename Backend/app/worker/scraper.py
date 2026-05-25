"""
Playwright scraping worker.

Fetches a page via headless Chromium, replays the recorded user interactions
(variant selections + price element tap), then fans the result out to every
active Tracker watching that URL.
"""
import asyncio
import logging
import re
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from typing import Optional

from playwright.async_api import async_playwright
from sqlalchemy import select

from app.alert_evaluator import should_alert
from app.config import settings
from app.database import AsyncSessionLocal
from app.models.price_snapshot import PriceSnapshot
from app.models.tracker import Tracker
from app.models.url_job import UrlJob
from app.models.user import User
from app.worker.celery_app import celery

logger = logging.getLogger(__name__)

_PRICE_RE = re.compile(r"[\d,]+\.?\d*")


async def _get_device_token(db, user_id) -> Optional[str]:
    result = await db.execute(select(User.apns_token).where(User.id == user_id))
    return result.scalar_one_or_none()


def _parse_price(raw_text: str) -> Optional[Decimal]:
    match = _PRICE_RE.search(raw_text)
    if not match:
        return None
    cleaned = match.group().replace(",", "")
    try:
        return Decimal(cleaned)
    except InvalidOperation:
        return None


async def _scrape_tracker(tracker: Tracker) -> tuple[Optional[str], Optional[Decimal]]:
    """Replay the tracker's recorded interactions via Playwright and return (raw_text, price)."""
    interactions = tracker.interactions or []
    if not interactions:
        return None, None

    browser_args: dict = {}
    if settings.PROXY_HOST:
        browser_args["proxy"] = {
            "server": f"http://{settings.PROXY_HOST}",
            "username": settings.PROXY_USER,
            "password": settings.PROXY_PASS,
        }

    async with async_playwright() as p:
        browser = await p.chromium.launch(**browser_args)
        page = await browser.new_page()
        try:
            await page.goto(tracker.url, wait_until="domcontentloaded", timeout=30000)
            # Give JS-rendered content a moment to settle after DOM is ready
            await page.wait_for_timeout(2000)

            # Replay all steps except the final price element tap
            for step in interactions[:-1]:
                if step.get("type") == "click":
                    locator = step.get("locator", "")
                    try:
                        await page.locator(locator).first.click(timeout=5000)
                        await page.wait_for_timeout(1000)
                    except Exception:
                        logger.warning("Interaction replay click failed: %s", locator)

            # Final step is the price element
            price_step = interactions[-1]
            locator = price_step.get("locator", "")
            try:
                el = page.locator(locator).first
                raw_text = await el.inner_text(timeout=5000)
                price = _parse_price(raw_text)
                return raw_text, price
            except Exception:
                logger.warning("Price element not found: %s", locator)
                return None, None
        finally:
            await browser.close()


async def _process_tracker(tracker: Tracker, now: datetime, session) -> None:
    raw_text, price = await _scrape_tracker(tracker)

    if price is not None:
        snapshot = PriceSnapshot(
            tracker_id=tracker.id,
            price=price,
            raw_text=raw_text,
        )
        session.add(snapshot)

        tracker.last_price = price
        tracker.last_checked_at = now
        tracker.last_successful_fetch_at = now
        tracker.failure_count = 0
        tracker.first_failure_at = None

        if should_alert(tracker, price, now):
            apns_token = await _get_device_token(session, tracker.user_id)
            if apns_token:
                from app.push_sender import send_price_alert
                await send_price_alert(apns_token, tracker, price)
            tracker.last_notified_at = now
            tracker.last_notified_price = price
    else:
        tracker.last_checked_at = now
        tracker.failure_count = (tracker.failure_count or 0) + 1
        if tracker.failure_count == 1:
            tracker.first_failure_at = now


async def _fetch_and_process(url: str) -> None:
    now = datetime.now(tz=timezone.utc)

    async with AsyncSessionLocal() as session:
        trackers_result = await session.execute(
            select(Tracker).where(Tracker.url == url, Tracker.status == "active")
        )
        trackers = trackers_result.scalars().all()

        for tracker in trackers:
            await _process_tracker(tracker, now, session)

        url_job_result = await session.execute(select(UrlJob).where(UrlJob.url == url))
        url_job = url_job_result.scalar_one_or_none()
        if url_job is not None:
            url_job.last_fetched_at = now
            url_job.fetch_status = "done"

        await session.commit()


# ---------------------------------------------------------------------------
# Celery task
# ---------------------------------------------------------------------------

@celery.task(name="app.worker.scraper.scrape_url")
def scrape_url(url: str) -> None:
    """Replay recorded interactions for every active Tracker on *url* and evaluate alerts."""
    try:
        asyncio.run(_fetch_and_process(url))
    except Exception:
        logger.exception("scrape_url failed for %s", url)
