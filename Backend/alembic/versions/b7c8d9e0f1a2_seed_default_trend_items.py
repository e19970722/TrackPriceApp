"""seed default global "On Trend" items

Inserts a system seed user plus three global seed trackers (each with two
price snapshots that yield a deterministic, non-zero downward delta) so the
Home "On Trend Tracks" section is never empty, even for a brand-new account.

Data lives in ``app.seed_data`` — this migration only materialises it.

Revision ID: b7c8d9e0f1a2
Revises: adea41532432
Create Date: 2026-07-09

"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op
from app.seed_data import (
    SEED_ITEMS,
    SEED_TRACKER_IDS,
    SEED_USER_AUTH_PROVIDER,
    SEED_USER_AUTH_PROVIDER_ID,
    SEED_USER_ID,
)

revision: str = "b7c8d9e0f1a2"
down_revision: Union[str, None] = "adea41532432"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


users_table = sa.table(
    "users",
    sa.column("id", sa.UUID()),
    sa.column("auth_provider", sa.String()),
    sa.column("auth_provider_id", sa.String()),
    sa.column("email", sa.String()),
    sa.column("display_name", sa.String()),
)

trackers_table = sa.table(
    "trackers",
    sa.column("id", sa.UUID()),
    sa.column("user_id", sa.UUID()),
    sa.column("url", sa.String()),
    sa.column("name", sa.String()),
    sa.column("interactions", sa.JSON()),
    sa.column("currency_symbol", sa.String()),
    sa.column("target_price", sa.Numeric()),
    sa.column("target_direction", sa.String()),
    sa.column("status", sa.String()),
    sa.column("item_name", sa.String()),
    sa.column("item_image_url", sa.String()),
    sa.column("last_price", sa.Numeric()),
    sa.column("last_checked_at", sa.DateTime(timezone=True)),
)

snapshots_table = sa.table(
    "price_snapshots",
    sa.column("tracker_id", sa.UUID()),
    sa.column("price", sa.Numeric()),
    sa.column("raw_text", sa.String()),
    sa.column("scraped_at", sa.DateTime(timezone=True)),
)


def upgrade() -> None:
    now = datetime.now(timezone.utc)
    baseline_at = now - timedelta(days=2)

    op.bulk_insert(
        users_table,
        [
            {
                "id": SEED_USER_ID,
                "auth_provider": SEED_USER_AUTH_PROVIDER,
                "auth_provider_id": SEED_USER_AUTH_PROVIDER_ID,
                "email": None,
                "display_name": "TrackPrice",
            }
        ],
    )

    op.bulk_insert(
        trackers_table,
        [
            {
                "id": item.tracker_id,
                "user_id": SEED_USER_ID,
                "url": item.url,
                "name": item.name,
                "interactions": [],
                "currency_symbol": item.currency_symbol,
                "target_price": item.current_price,
                "target_direction": "below",
                "status": "active",
                "item_name": item.item_name,
                "item_image_url": item.item_image_url,
                "last_price": item.current_price,
                "last_checked_at": now,
            }
            for item in SEED_ITEMS
        ],
    )

    snapshot_rows: list[dict] = []
    for item in SEED_ITEMS:
        snapshot_rows.append(
            {
                "tracker_id": item.tracker_id,
                "price": item.baseline_price,
                "raw_text": str(item.baseline_price),
                "scraped_at": baseline_at,
            }
        )
        snapshot_rows.append(
            {
                "tracker_id": item.tracker_id,
                "price": item.current_price,
                "raw_text": str(item.current_price),
                "scraped_at": now,
            }
        )
    op.bulk_insert(snapshots_table, snapshot_rows)


def downgrade() -> None:
    bind = op.get_bind()
    tracker_ids = [str(tid) for tid in SEED_TRACKER_IDS]
    bind.execute(
        sa.text("DELETE FROM price_snapshots WHERE tracker_id = ANY(:ids)"),
        {"ids": tracker_ids},
    )
    bind.execute(
        sa.text("DELETE FROM trackers WHERE id = ANY(:ids)"),
        {"ids": tracker_ids},
    )
    bind.execute(
        sa.text("DELETE FROM users WHERE id = :uid"),
        {"uid": str(SEED_USER_ID)},
    )
