import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict


class TrackerCreate(BaseModel):
    url: str
    name: str
    css_selector: str
    xpath: str
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
    css_selector: str
    currency_symbol: str
    target_price: Decimal
    target_direction: str
    status: str
    last_price: Optional[Decimal] = None
    last_checked_at: Optional[datetime] = None
    created_at: datetime


class PriceSnapshotOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    price: Decimal
    raw_text: str
    scraped_at: datetime
