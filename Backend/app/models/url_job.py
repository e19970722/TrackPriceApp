from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class UrlJob(Base):
    __tablename__ = "url_jobs"

    url: Mapped[str] = mapped_column(String(2048), primary_key=True)
    last_fetched_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    next_fetch_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    fetch_status: Mapped[str] = mapped_column(String(20), default="pending")
    last_html_hash: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
