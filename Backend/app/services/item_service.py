"""Business logic for item CRUD operations.

Wraps repository calls and enforces ownership.  Raises ValueError so the API
layer can convert to HTTP 404.
"""
from __future__ import annotations

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.item import Item
from app.models.user import User
from app.repositories import item_repo
from app.schemas.item import ItemIn, ItemOut, ItemUpdate


def build_item_out(item: Item) -> ItemOut:
    return ItemOut.model_validate(item)


async def list_user_items(
    db: AsyncSession, user: User, include_used: bool = False
) -> list[ItemOut]:
    items = await item_repo.get_items_for_user(db, user.id, include_used=include_used)
    return [build_item_out(i) for i in items]


async def create_user_item(db: AsyncSession, user: User, body: ItemIn) -> ItemOut:
    item = await item_repo.create_item(db, user.id, body)
    return build_item_out(item)


async def get_user_item(db: AsyncSession, item_id: UUID, user: User) -> ItemOut:
    item = await _require_owned(db, item_id, user.id)
    return build_item_out(item)


async def update_user_item(
    db: AsyncSession, item_id: UUID, user: User, body: ItemUpdate
) -> ItemOut:
    item = await _require_owned(db, item_id, user.id)
    updated = await item_repo.update_item(
        db, item, body.model_dump(exclude_none=True)
    )
    return build_item_out(updated)


async def mark_item_used(db: AsyncSession, item_id: UUID, user: User) -> ItemOut:
    item = await _require_owned(db, item_id, user.id)
    updated = await item_repo.update_item(db, item, {"is_used": True})
    return build_item_out(updated)


async def delete_user_item(db: AsyncSession, item_id: UUID, user: User) -> None:
    item = await _require_owned(db, item_id, user.id)
    await item_repo.delete_item(db, item)


async def _require_owned(db: AsyncSession, item_id: UUID, user_id: UUID) -> Item:
    item = await item_repo.get_owned_item(db, item_id, user_id)
    if item is None:
        raise ValueError("Item not found")
    return item
