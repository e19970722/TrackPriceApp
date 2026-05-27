"""Business logic for processing a tracker scrape result.

Orchestrates: fetch via Playwright, persist snapshot, evaluate alert,
dispatch push notification.  No HTTP concerns; receives and returns
domain objects only.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone
from uuid import UUID

from app.alert_evaluator import should_alert
from app.database import AsyncSessionLocal
from app.repositories import snapshot_repo, tracker_repo, user_repo
from app.worker.scraper import scrape_page

logger = logging.getLogger(__name__)


async def process_tracker_scrape(tracker_id: UUID) -> None:
    """Scrape *tracker_id*, persist result, and fire alert if warranted."""
    now = datetime.now(tz=timezone.utc)

    async with AsyncSessionLocal() as session:
        tracker = await tracker_repo.get_tracker_by_id(session, tracker_id)
        if tracker is None:
            logger.warning("process_tracker_scrape: tracker %s not found", tracker_id)
            return

        raw_text, price, og_title, og_image = await scrape_page(
            tracker.url, tracker.interactions or []
        )

        if tracker.item_name is None and og_title:
            tracker.item_name = og_title
        if tracker.item_image_url is None and og_image:
            tracker.item_image_url = og_image

        if price is not None:
            await snapshot_repo.create_snapshot(session, tracker.id, price, raw_text or "")
            tracker.last_price = float(price)
            tracker.last_checked_at = now
            tracker.last_successful_fetch_at = now
            tracker.failure_count = 0
            tracker.first_failure_at = None

            if should_alert(tracker, price, now):
                apns_token = await user_repo.get_apns_token(session, tracker.user_id)
                if apns_token:
                    from app.push_sender import send_price_alert  # noqa: PLC0415

                    await send_price_alert(apns_token, tracker, price)
                tracker.last_notified_at = now
                tracker.last_notified_price = float(price)
        else:
            tracker.last_checked_at = now
            tracker.failure_count = (tracker.failure_count or 0) + 1
            if tracker.failure_count == 1:
                tracker.first_failure_at = now

        await session.commit()
