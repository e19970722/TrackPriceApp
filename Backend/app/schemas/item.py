"""Pydantic schemas for the items (expiry-date tracker) endpoints."""
from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, computed_field, field_validator

VALID_LOCATIONS = frozenset({"fridge", "pantry", "freezer", "custom"})


class ItemIn(BaseModel):
    name: str
    quantity: Optional[str] = None
    location: Optional[str] = None
    location_custom: Optional[str] = None
    best_before_date: date
    added_date: Optional[date] = None
    remind_days_before: int = 3
    remind_on_day: bool = False

    @field_validator("location")
    @classmethod
    def validate_location(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_LOCATIONS:
            raise ValueError(f"location must be one of {sorted(VALID_LOCATIONS)}")
        return v


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    quantity: Optional[str] = None
    location: Optional[str] = None
    location_custom: Optional[str] = None
    best_before_date: Optional[date] = None
    remind_days_before: Optional[int] = None
    remind_on_day: Optional[bool] = None
    is_used: Optional[bool] = None

    @field_validator("location")
    @classmethod
    def validate_location(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in VALID_LOCATIONS:
            raise ValueError(f"location must be one of {sorted(VALID_LOCATIONS)}")
        return v


class ItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    name: str
    quantity: Optional[str] = None
    location: Optional[str] = None
    location_custom: Optional[str] = None
    best_before_date: date
    added_date: date
    remind_days_before: int
    remind_on_day: bool
    is_used: bool
    created_at: datetime

    @computed_field  # type: ignore[prop-decorator]
    @property
    def days_left(self) -> int:
        """Signed days until best_before_date from today. Negative = already expired."""
        from datetime import date as date_type  # local import avoids circular refs

        return (self.best_before_date - date_type.today()).days

    @computed_field  # type: ignore[prop-decorator]
    @property
    def remind_on(self) -> date:
        """The calendar date on which the advance reminder fires."""
        from datetime import timedelta

        return self.best_before_date - timedelta(days=self.remind_days_before)

    @computed_field  # type: ignore[prop-decorator]
    @property
    def freshness(self) -> Literal["fresh", "expiring", "expired"]:
        """
        'expired'  — best_before_date is in the past
        'expiring' — within remind_days_before days (inclusive)
        'fresh'    — more than remind_days_before days away
        """
        d = self.days_left
        if d < 0:
            return "expired"
        if d <= self.remind_days_before:
            return "expiring"
        return "fresh"
