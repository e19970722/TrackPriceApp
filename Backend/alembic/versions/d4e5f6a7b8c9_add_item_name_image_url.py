"""add item_name and item_image_url to trackers

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
Create Date: 2026-05-26

"""
from alembic import op
import sqlalchemy as sa

revision = "d4e5f6a7b8c9"
down_revision = "c3d4e5f6a7b8"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("trackers", sa.Column("item_name", sa.String(), nullable=True))
    op.add_column("trackers", sa.Column("item_image_url", sa.String(2048), nullable=True))


def downgrade() -> None:
    op.drop_column("trackers", "item_image_url")
    op.drop_column("trackers", "item_name")
