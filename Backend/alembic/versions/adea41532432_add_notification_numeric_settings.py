"""add notification numeric settings columns to users

Revision ID: adea41532432
Revises: f6a7b8c9d0e1
Create Date: 2026-07-09

"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

revision: str = "adea41532432"
down_revision: Union[str, None] = "f6a7b8c9d0e1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "expiring_soon_days_before", sa.Integer(), nullable=False, server_default="3"
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "running_low_threshold", sa.Integer(), nullable=False, server_default="1"
        ),
    )


def downgrade() -> None:
    op.drop_column("users", "running_low_threshold")
    op.drop_column("users", "expiring_soon_days_before")
