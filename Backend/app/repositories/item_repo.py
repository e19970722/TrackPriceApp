"""SQLAlchemy queries for the Item model."""
from __future__ import annotations

from datetime import date
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.item import Item
from app.schemas.item import ItemIn


async def get_items_for_user(
    db: AsyncSession,
    user_id: UUID,
    include_used: bool = False,
) -> list[Item]:
    stmt = select(Item).where(Item.user_id == user_id)
    if not include_used:
        stmt = stmt.where(Item.is_used.is_(False))
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_item_by_id(db: AsyncSession, item_id: UUID) -> Item | None:
    result = await db.execute(select(Item).where(Item.id == item_id))
    return result.scalar_one_or_none()


async def get_owned_item(
    db: AsyncSession, item_id: UUID, user_id: UUID
) -> Item | None:
    result = await db.execute(
        select(Item).where(Item.id == item_id, Item.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create_item(db: AsyncSession, user_id: UUID, body: ItemIn) -> Item:
    from datetime import date as date_type

    item = Item(
        user_id=user_id,
        name=body.name,
        quantity=body.quantity,
        location=body.location,
        location_custom=body.location_custom,
        best_before_date=body.best_before_date,
        added_date=body.added_date if body.added_date is not None else date_type.today(),
        remind_days_before=body.remind_days_before,
        remind_on_day=body.remind_on_day,
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item


async def update_item(db: AsyncSession, item: Item, fields: dict) -> Item:
    for field, value in fields.items():
        setattr(item, field, value)
    await db.commit()
    await db.refresh(item)
    return item


async def delete_item(db: AsyncSession, item: Item) -> None:
    await db.delete(item)
    await db.commit()


async def get_items_due_for_reminder(db: AsyncSession, today: date) -> list[Item]:
    """Return active items whose advance-reminder date equals today."""

    from sqlalchemy import func

    # best_before_date - remind_days_before == today
    # Equivalent: best_before_date == today + remind_days_before
    # We compute this in Python per-row via a column expression.
    # For a large table use a generated column; here a simple filter is fine.
    result = await db.execute(
        select(Item).where(
            Item.is_used.is_(False),
            func.date(Item.best_before_date) - Item.remind_days_before
            == today,
        )
    )
    return list(result.scalars().all())


async def get_items_expiring_today(db: AsyncSession, today: date) -> list[Item]:
    """Return active items whose best_before_date is today and remind_on_day is set."""
    result = await db.execute(
        select(Item).where(
            Item.is_used.is_(False),
            Item.remind_on_day.is_(True),
            Item.best_before_date == today,
        )
    )
    return list(result.scalars().all())
