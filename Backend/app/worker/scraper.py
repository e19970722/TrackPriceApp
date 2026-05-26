import asyncio
import logging
import re
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from typing import Optional
from uuid import UUID

from playwright.async_api import async_playwright
from sqlalchemy import select

from app.alert_evaluator import should_alert
from app.config import settings
from app.database import AsyncSessionLocal
from app.models.price_snapshot import PriceSnapshot
from app.models.tracker import Tracker
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


async def _scrape_tracker(tracker: Tracker) -> tuple[Optional[str], Optional[Decimal], Optional[str], Optional[str]]:
    """Replay the tracker's recorded interactions via Playwright and return (raw_text, price, og_title, og_image)."""
    interactions = tracker.interactions or []
    if not interactions:
        return None, None, None, None

    browser_args: dict = {}
    if settings.PROXY_HOST:
        browser_args["proxy"] = {
            "server": f"http://{settings.PROXY_HOST}",
            "username": settings.PROXY_USER,
            "password": settings.PROXY_PASS,
        }

    browser_args["args"] = list(browser_args.get("args", [])) + [
        "--disable-blink-features=AutomationControlled",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--no-first-run",
    ]

    async with async_playwright() as p:
        browser = await p.chromium.launch(**browser_args)
        context = await browser.new_context(
            user_agent=(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 "
                "Mobile/15E148 Safari/604.1"
            ),
            viewport={"width": 390, "height": 844},
            device_scale_factor=3,
            is_mobile=True,
            has_touch=True,
            extra_http_headers={
                "Accept-Language": "zh-TW,zh;q=0.9,en;q=0.8",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            },
            ignore_https_errors=True,
        )
        page = await context.new_page()
        try:
            try:
                await page.goto(tracker.url, wait_until="domcontentloaded", timeout=60000)
            except Exception as nav_err:
                logger.warning("Navigation warning for %s: %s", tracker.url, nav_err)
                await page.wait_for_timeout(3000)
            await page.wait_for_timeout(2000)

            og_title: Optional[str] = None
            og_image: Optional[str] = None
            try:
                og_title = await page.locator('meta[property="og:title"]').get_attribute("content", timeout=3000)
            except Exception:
                pass
            try:
                raw_img = await page.locator('meta[property="og:image"]').get_attribute("content", timeout=3000)
                if raw_img:
                    from urllib.parse import urljoin
                    og_image = urljoin(tracker.url, raw_img)
            except Exception:
                pass

            for step in interactions[:-1]:
                if step.get("type") == "click":
                    locator = step.get("locator", "")
                    try:
                        await page.locator(locator).first.click(timeout=5000)
                        await page.wait_for_timeout(1000)
                    except Exception:
                        logger.warning("Interaction replay click failed: %s", locator)

            price_step = interactions[-1]
            locator = price_step.get("locator", "")
            try:
                el = page.locator(locator).first
                raw_text = await el.inner_text(timeout=5000)
                price = _parse_price(raw_text)
                return raw_text, price, og_title, og_image
            except Exception:
                logger.warning("Price element not found: %s", locator)
                return None, None, og_title, og_image
        finally:
            await context.close()
            await browser.close()


async def _process(tracker_id: UUID) -> None:
    now = datetime.now(tz=timezone.utc)

    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Tracker).where(Tracker.id == tracker_id))
        tracker = result.scalar_one_or_none()
        if tracker is None:
            logger.warning("scrape_tracker: tracker %s not found", tracker_id)
            return

        raw_text, price, og_title, og_image = await _scrape_tracker(tracker)

        if tracker.item_name is None and og_title:
            tracker.item_name = og_title
        if tracker.item_image_url is None and og_image:
            tracker.item_image_url = og_image

        if price is not None:
            session.add(PriceSnapshot(tracker_id=tracker.id, price=price, raw_text=raw_text))
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

        await session.commit()


@celery.task(name="app.worker.scraper.scrape_tracker")
def scrape_tracker(tracker_id: str) -> None:
    try:
        asyncio.run(_process(UUID(tracker_id)))
    except Exception:
        logger.exception("scrape_tracker failed for %s", tracker_id)
