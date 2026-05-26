"""drop url_jobs table

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-05-26
"""
from alembic import op
import sqlalchemy as sa

revision = "c3d4e5f6a7b8"
down_revision = "b2c3d4e5f6a7"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_table("url_jobs")


def downgrade() -> None:
    op.create_table(
        "url_jobs",
        sa.Column("url", sa.String(2048), primary_key=True),
        sa.Column("last_fetched_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("next_fetch_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("fetch_status", sa.String(20), server_default="pending"),
        sa.Column("last_html_hash", sa.String(64), nullable=True),
    )
