"""SQLAlchemy model for the items (expiry-date tracker) table."""
from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Index, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class Item(Base):
    __tablename__ = "items"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String, nullable=False)
    quantity: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    location: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    location_custom: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    best_before_date: Mapped[date] = mapped_column(Date, nullable=False)
    added_date: Mapped[date] = mapped_column(
        Date, nullable=False, server_default=func.current_date()
    )
    remind_days_before: Mapped[int] = mapped_column(Integer, nullable=False, default=3)
    remind_on_day: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_used: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    __table_args__ = (
        Index("ix_items_user_id_is_used", "user_id", "is_used"),
        Index("ix_items_best_before_date", "best_before_date"),
    )
