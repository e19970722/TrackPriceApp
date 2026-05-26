"""Playwright page interaction — returns (raw_text, price, og_title, og_image).

This module is responsible solely for browser automation.  All database
access, alert evaluation, and push dispatch are handled in price_service.
"""
import asyncio
import logging
import re
from decimal import Decimal, InvalidOperation
from typing import Optional
from uuid import UUID

from playwright.async_api import async_playwright

from app.config import settings
from app.worker.celery_app import celery
from app.worker.og_extractor import extract_og_tags

logger = logging.getLogger(__name__)

_PRICE_RE = re.compile(r"[\d,]+\.?\d*")


def _parse_price(raw_text: str) -> Optional[Decimal]:
    match = _PRICE_RE.search(raw_text)
    if not match:
        return None
    cleaned = match.group().replace(",", "")
    try:
        return Decimal(cleaned)
    except InvalidOperation:
        return None


async def scrape_page(
    url: str,
    interactions: list[dict],
) -> tuple[Optional[str], Optional[Decimal], Optional[str], Optional[str]]:
    """Drive a headless browser through *interactions* and return scraped data.

    Returns:
        (raw_text, price, og_title, og_image)
        Any element may be None if extraction fails.
    """
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
                await page.goto(url, wait_until="domcontentloaded", timeout=60000)
            except Exception as nav_err:
                logger.warning("Navigation warning for %s: %s", url, nav_err)
                await page.wait_for_timeout(3000)
            await page.wait_for_timeout(2000)

            og_title, og_image = await extract_og_tags(page, url)

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


@celery.task(name="app.worker.scraper.scrape_tracker")
def scrape_tracker(tracker_id: str) -> None:
    from app.services.price_service import process_tracker_scrape  # noqa: PLC0415

    try:
        asyncio.run(process_tracker_scrape(UUID(tracker_id)))
    except Exception:
        logger.exception("scrape_tracker failed for %s", tracker_id)
