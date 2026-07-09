import uuid
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, computed_field


class NotificationPreferences(BaseModel):
    price_drops: bool
    expiring_soon: bool
    running_low: bool
    weekly_digest: bool
    expiring_soon_days_before: int
    running_low_threshold: int


class NotificationPreferencesUpdate(BaseModel):
    """Partial update — omitted keys leave the stored preference unchanged."""

    price_drops: Optional[bool] = None
    expiring_soon: Optional[bool] = None
    running_low: Optional[bool] = None
    weekly_digest: Optional[bool] = None
    expiring_soon_days_before: Optional[int] = Field(default=None, ge=1, le=30)
    running_low_threshold: Optional[int] = Field(default=None, ge=1, le=99)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: Optional[str] = None
    display_name: Optional[str] = None
    subscription_tier: str
    auth_provider: str

    # Flat DB columns — validated from the ORM object, hidden from the response.
    notify_price_drops: bool = Field(default=True, exclude=True)
    notify_expiring_soon: bool = Field(default=True, exclude=True)
    notify_running_low: bool = Field(default=True, exclude=True)
    notify_weekly_digest: bool = Field(default=False, exclude=True)
    expiring_soon_days_before: int = Field(default=3, exclude=True)
    running_low_threshold: int = Field(default=1, exclude=True)

    @computed_field  # type: ignore[prop-decorator]
    @property
    def notification_preferences(self) -> NotificationPreferences:
        return NotificationPreferences(
            price_drops=self.notify_price_drops,
            expiring_soon=self.notify_expiring_soon,
            running_low=self.notify_running_low,
            weekly_digest=self.notify_weekly_digest,
            expiring_soon_days_before=self.expiring_soon_days_before,
            running_low_threshold=self.running_low_threshold,
        )


class UserUpdate(BaseModel):
    apns_token: Optional[str] = None
    notification_preferences: Optional[NotificationPreferencesUpdate] = None
