"""
Playwright scraping worker.

One Celery task — scrape_url — fetches a page via headless Chromium (with an
optional residential proxy) and fans the result out to every active Tracker
watching that URL.
"""
import asyncio
import hashlib
import logging
import re
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from typing import Optional

from bs4 import BeautifulSoup
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
    """Return the APNs token for *user_id*, or None if absent."""
    result = await db.execute(
        select(User.apns_token).where(User.id == user_id)
    )
    return result.scalar_one_or_none()


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _parse_price(raw_text: str) -> Optional[Decimal]:
    """Extract the first numeric price from a raw text string."""
    match = _PRICE_RE.search(raw_text)
    if not match:
        return None
    cleaned = match.group().replace(",", "")
    try:
        return Decimal(cleaned)
    except InvalidOperation:
        return None


async def _process_url_results(url: str, html: str) -> None:
    """Apply scraped HTML to all active Trackers watching *url* and update UrlJob."""
    html_hash = hashlib.md5(html.encode()).hexdigest()
    now = datetime.now(tz=timezone.utc)

    async with AsyncSessionLocal() as session:
        trackers_result = await session.execute(
            select(Tracker).where(Tracker.url == url, Tracker.status == "active")
        )
        trackers = trackers_result.scalars().all()

        soup = BeautifulSoup(html, "html.parser")

        for tracker in trackers:
            el = soup.select_one(tracker.css_selector)
            raw_text = el.get_text(strip=True) if el else None

            if raw_text is not None:
                price = _parse_price(raw_text)
            else:
                price = None

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

        url_job_result = await session.execute(
            select(UrlJob).where(UrlJob.url == url)
        )
        url_job = url_job_result.scalar_one_or_none()
        if url_job is not None:
            url_job.last_fetched_at = now
            url_job.fetch_status = "done"
            url_job.last_html_hash = html_hash

        await session.commit()


async def _fetch_and_process(url: str) -> None:
    """Launch Playwright, fetch the page, then delegate DB work."""
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
        await page.goto(url, wait_until="networkidle", timeout=15000)
        html = await page.content()
        await browser.close()

    await _process_url_results(url, html)


# ---------------------------------------------------------------------------
# Celery task
# ---------------------------------------------------------------------------


@celery.task(name="app.worker.scraper.scrape_url")
def scrape_url(url: str) -> None:
    """Fetch *url* and evaluate CSS selectors for every active Tracker on it."""
    try:
        asyncio.run(_fetch_and_process(url))
    except Exception:
        logger.exception("scrape_url failed for %s", url)
