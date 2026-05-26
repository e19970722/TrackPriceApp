import uuid
from datetime import datetime
from typing import TYPE_CHECKING, List, Optional

from sqlalchemy import DateTime, ForeignKey, Index, Integer, Numeric, String, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.price_snapshot import PriceSnapshot


class Tracker(Base):
    __tablename__ = "trackers"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    url: Mapped[str] = mapped_column(String(2048))
    name: Mapped[str] = mapped_column(String(255))
    interactions: Mapped[list] = mapped_column(JSONB, default=list)
    currency_symbol: Mapped[str] = mapped_column(String(10))
    target_price: Mapped[float] = mapped_column(Numeric(14, 2))
    target_direction: Mapped[str] = mapped_column(String(10))  # "below" | "above"
    check_interval: Mapped[int] = mapped_column(Integer, default=180)
    status: Mapped[str] = mapped_column(String(10), default="active")
    last_price: Mapped[Optional[float]] = mapped_column(Numeric(14, 2), nullable=True)
    last_checked_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_successful_fetch_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    failure_count: Mapped[int] = mapped_column(Integer, default=0)
    first_failure_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_notified_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_notified_price: Mapped[Optional[float]] = mapped_column(
        Numeric(14, 2), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    price_snapshots: Mapped[List["PriceSnapshot"]] = relationship(
        "PriceSnapshot", back_populates="tracker", cascade="all, delete-orphan"
    )

    __table_args__ = (Index("ix_trackers_url", "url"),)
