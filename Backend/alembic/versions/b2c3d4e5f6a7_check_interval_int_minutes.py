"""check_interval int minutes

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-05-26
"""
from alembic import op
import sqlalchemy as sa

revision = "b2c3d4e5f6a7"
down_revision = "a1b2c3d4e5f6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TABLE trackers ALTER COLUMN check_interval DROP DEFAULT")
    op.execute("""
        ALTER TABLE trackers
        ALTER COLUMN check_interval TYPE INTEGER
        USING CASE check_interval
            WHEN 'hourly' THEN 60
            WHEN '3h'     THEN 180
            ELSE 1440
        END
    """)
    op.execute("ALTER TABLE trackers ALTER COLUMN check_interval SET DEFAULT 180")


def downgrade() -> None:
    op.execute("ALTER TABLE trackers ALTER COLUMN check_interval DROP DEFAULT")
    op.execute("""
        ALTER TABLE trackers
        ALTER COLUMN check_interval TYPE VARCHAR(10)
        USING CASE check_interval
            WHEN 60   THEN 'hourly'
            WHEN 180  THEN '3h'
            ELSE 'daily'
        END
    """)
    op.execute("ALTER TABLE trackers ALTER COLUMN check_interval SET DEFAULT '3h'")
