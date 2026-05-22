import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.tracker import Tracker


class PriceSnapshot(Base):
    __tablename__ = "price_snapshots"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    tracker_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("trackers.id", ondelete="CASCADE")
    )
    price: Mapped[float] = mapped_column(Numeric(14, 2))
    raw_text: Mapped[str] = mapped_column(String(512))
    scraped_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    tracker: Mapped["Tracker"] = relationship("Tracker", back_populates="price_snapshots")

    __table_args__ = (
        Index("ix_price_snapshots_tracker_scraped", "tracker_id", "scraped_at"),
    )
