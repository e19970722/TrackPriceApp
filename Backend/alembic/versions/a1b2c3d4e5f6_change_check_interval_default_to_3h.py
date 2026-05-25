"""change_check_interval_default_to_3h

Revision ID: a1b2c3d4e5f6
Revises: f4a0e26497af
Create Date: 2026-05-25 00:00:00.000000

"""
from alembic import op

revision = "a1b2c3d4e5f6"
down_revision = "f4a0e26497af"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column("trackers", "check_interval", server_default="3h")


def downgrade() -> None:
    op.alter_column("trackers", "check_interval", server_default="daily")
