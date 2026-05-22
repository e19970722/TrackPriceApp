"""create initial schema

Revision ID: 0001
Revises:
Create Date: 2026-05-21 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("auth_provider", sa.String(length=20), nullable=False),
        sa.Column("auth_provider_id", sa.String(length=255), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("apns_token", sa.String(length=512), nullable=True),
        sa.Column("subscription_tier", sa.String(length=20), nullable=False, server_default="free"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("auth_provider_id"),
    )
    op.create_index("ix_users_auth_provider_id", "users", ["auth_provider_id"])

    op.create_table(
        "trackers",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("url", sa.String(length=2048), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("css_selector", sa.String(length=1024), nullable=False),
        sa.Column("xpath", sa.String(length=1024), nullable=False),
        sa.Column("currency_symbol", sa.String(length=10), nullable=False),
        sa.Column("target_price", sa.Numeric(14, 2), nullable=False),
        sa.Column("target_direction", sa.String(length=10), nullable=False),
        sa.Column("check_interval", sa.String(length=10), nullable=False, server_default="daily"),
        sa.Column("status", sa.String(length=10), nullable=False, server_default="active"),
        sa.Column("last_price", sa.Numeric(14, 2), nullable=True),
        sa.Column("last_checked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_successful_fetch_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("failure_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("first_failure_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_notified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_notified_price", sa.Numeric(14, 2), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_trackers_user_id", "trackers", ["user_id"])
    op.create_index("ix_trackers_url", "trackers", ["url"])

    op.create_table(
        "price_snapshots",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("tracker_id", sa.UUID(), nullable=False),
        sa.Column("price", sa.Numeric(14, 2), nullable=False),
        sa.Column("raw_text", sa.String(length=512), nullable=False),
        sa.Column("scraped_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.ForeignKeyConstraint(["tracker_id"], ["trackers.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_price_snapshots_tracker_scraped", "price_snapshots", ["tracker_id", "scraped_at"])

    op.create_table(
        "url_jobs",
        sa.Column("url", sa.String(length=2048), nullable=False),
        sa.Column("last_fetched_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("next_fetch_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("fetch_status", sa.String(length=20), nullable=False, server_default="pending"),
        sa.Column("last_html_hash", sa.String(length=64), nullable=True),
        sa.PrimaryKeyConstraint("url"),
    )


def downgrade() -> None:
    op.drop_table("url_jobs")
    op.drop_index("ix_price_snapshots_tracker_scraped", table_name="price_snapshots")
    op.drop_table("price_snapshots")
    op.drop_index("ix_trackers_url", table_name="trackers")
    op.drop_index("ix_trackers_user_id", table_name="trackers")
    op.drop_table("trackers")
    op.drop_index("ix_users_auth_provider_id", table_name="users")
    op.drop_table("users")
