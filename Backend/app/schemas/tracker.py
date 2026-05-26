import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict


class TrackerCreate(BaseModel):
    url: str
    name: str
    interactions: list[dict]
    currency_symbol: str
    confirmed_price: Decimal
    target_price: Decimal
    target_direction: str  # "below" | "above"


class TrackerUpdate(BaseModel):
    name: Optional[str] = None
    target_price: Optional[Decimal] = None
    target_direction: Optional[str] = None
    status: Optional[str] = None  # "active" | "paused"


class TrackerOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    url: str
    name: str
    currency_symbol: str
    target_price: float
    target_direction: str
    check_interval: int
    status: str
    interactions: list[dict] = []
    last_price: Optional[float] = None
    last_checked_at: Optional[datetime] = None
    next_checked_at: Optional[datetime] = None
    created_at: datetime


class PriceSnapshotOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tracker_id: uuid.UUID
    price: float
    raw_text: str
    scraped_at: datetime
