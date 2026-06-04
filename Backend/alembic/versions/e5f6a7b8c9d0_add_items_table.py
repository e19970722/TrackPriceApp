"""add items table for expiry-date tracking

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-06-02

"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "e5f6a7b8c9d0"
down_revision: Union[str, None] = "d4e5f6a7b8c9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "items",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("quantity", sa.String(), nullable=True),
        sa.Column("location", sa.String(length=20), nullable=True),
        sa.Column("location_custom", sa.String(), nullable=True),
        sa.Column("best_before_date", sa.Date(), nullable=False),
        sa.Column(
            "added_date",
            sa.Date(),
            nullable=False,
            server_default=sa.text("CURRENT_DATE"),
        ),
        sa.Column("remind_days_before", sa.Integer(), nullable=False, server_default="3"),
        sa.Column("remind_on_day", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("is_used", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_items_user_id_is_used", "items", ["user_id", "is_used"])
    op.create_index("ix_items_best_before_date", "items", ["best_before_date"])


def downgrade() -> None:
    op.drop_index("ix_items_best_before_date", table_name="items")
    op.drop_index("ix_items_user_id_is_used", table_name="items")
    op.drop_table("items")
