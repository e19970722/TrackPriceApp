import uuid
from typing import Optional

from pydantic import BaseModel, ConfigDict


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: Optional[str] = None
    subscription_tier: str
    auth_provider: str


class UserUpdate(BaseModel):
    apns_token: Optional[str] = None
