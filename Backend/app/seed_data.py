"""Default global "On Trend" seed data.

These items are owned by a fixed system *seed user* so that they surface in the
global ``GET /trackers/trends`` feed for every user, including brand-new
accounts that have no trackers of their own.

This module is the single source of truth for the seed identifiers and prices.
The Alembic migration ``b7c8d9e0f1a2_seed_default_trend_items`` inserts these
rows verbatim; keep the two in sync if you ever change them.

Deltas are deterministic: each seed tracker gets two snapshots (a higher
``baseline_price`` followed by the lower ``current_price``), so ``compute_trends``
reports a stable, non-zero downward ``delta_percent`` without any real scraping.
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass
from decimal import Decimal

# Fixed system user that owns every seed tracker.
SEED_USER_ID = uuid.UUID("00000000-0000-0000-0000-0000000000aa")
SEED_USER_AUTH_PROVIDER = "system"
SEED_USER_AUTH_PROVIDER_ID = "system-seed-user"


@dataclass(frozen=True)
class SeedItem:
    tracker_id: uuid.UUID
    name: str
    url: str
    currency_symbol: str
    # baseline_price is the older snapshot; current_price is the latest one.
    # The gap yields a deterministic, non-zero downward delta_percent.
    baseline_price: Decimal
    current_price: Decimal
    item_name: str
    item_image_url: str | None = None


SEED_ITEMS: list[SeedItem] = [
    SeedItem(
        tracker_id=uuid.UUID("00000000-0000-0000-0000-0000000000b1"),
        name=(
            "Apple 蘋果MacBook Pro 14 M5 晶片 10核心 CPU、10核心 GPU、"
            "24GB 統一記憶體、1TB SSD"
        ),
        url="https://24h.pchome.com.tw/prod/DYAJEP-A900JCMV4",
        currency_symbol="$",
        baseline_price=Decimal("74172.00"),  # ~5.3% above current
        current_price=Decimal("70462.00"),
        item_name=(
            "Apple 蘋果MacBook Pro 14 M5 晶片 10核心 CPU、10核心 GPU、"
            "24GB 統一記憶體、1TB SSD"
        ),
    ),
    SeedItem(
        tracker_id=uuid.UUID("00000000-0000-0000-0000-0000000000b2"),
        name=(
            "Owala Freesip 三層不鏽鋼保溫杯｜專利雙飲口｜480ml/16oz"
            "(彈蓋真空/保溫保冰杯/運動水壺/絕飲杯)"
        ),
        url="https://www.momoshop.com.tw/product/15333514",
        currency_symbol="$",
        baseline_price=Decimal("899.00"),  # ~16.7% above current
        current_price=Decimal("749.00"),
        item_name=(
            "Owala Freesip 三層不鏽鋼保溫杯｜專利雙飲口｜480ml/16oz"
            "(彈蓋真空/保溫保冰杯/運動水壺/絕飲杯)"
        ),
    ),
    SeedItem(
        tracker_id=uuid.UUID("00000000-0000-0000-0000-0000000000b3"),
        name="Salomon SPEEDCROSS 3 GORE-TEX",
        url="https://salomon.com.tw/products/salomon-speedcross-3-gore-tex",
        currency_symbol="$",
        baseline_price=Decimal("6480.00"),  # ~10.8% above current
        current_price=Decimal("5780.00"),
        item_name="Salomon SPEEDCROSS 3 GORE-TEX",
    ),
]

SEED_TRACKER_IDS = {item.tracker_id for item in SEED_ITEMS}
