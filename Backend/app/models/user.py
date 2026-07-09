import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    auth_provider: Mapped[str] = mapped_column(String(20))  # "apple" | "google"
    auth_provider_id: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    display_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    apns_token: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    subscription_tier: Mapped[str] = mapped_column(String(20), default="free")
    notify_price_drops: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default="true"
    )
    notify_expiring_soon: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default="true"
    )
    notify_running_low: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default="true"
    )
    notify_weekly_digest: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="false"
    )
    expiring_soon_days_before: Mapped[int] = mapped_column(
        Integer, default=3, server_default="3"
    )
    running_low_threshold: Mapped[int] = mapped_column(
        Integer, default=1, server_default="1"
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
