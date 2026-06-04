"""CRUD endpoints for the items (expiry-date tracker) resource."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.item import ItemIn, ItemOut, ItemUpdate
from app.services import item_service

router = APIRouter(prefix="/items", tags=["items"])


@router.post("", response_model=ItemOut, status_code=status.HTTP_201_CREATED)
async def create_item(
    body: ItemIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ItemOut:
    return await item_service.create_user_item(db, current_user, body)


@router.get("", response_model=list[ItemOut])
async def list_items(
    include_used: bool = Query(False, description="Include items already marked as used"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[ItemOut]:
    return await item_service.list_user_items(db, current_user, include_used=include_used)


@router.get("/{item_id}", response_model=ItemOut)
async def get_item(
    item_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ItemOut:
    return await _get_or_404(db, item_id, current_user)


@router.patch("/{item_id}", response_model=ItemOut)
async def update_item(
    item_id: UUID,
    body: ItemUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ItemOut:
    try:
        return await item_service.update_user_item(db, item_id, current_user, body)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT, response_model=None)
async def delete_item(
    item_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    try:
        await item_service.delete_user_item(db, item_id, current_user)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")


@router.post("/{item_id}/mark-used", response_model=ItemOut)
async def mark_item_used(
    item_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ItemOut:
    try:
        return await item_service.mark_item_used(db, item_id, current_user)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")


async def _get_or_404(db: AsyncSession, item_id: UUID, user: User) -> ItemOut:
    try:
        return await item_service.get_user_item(db, item_id, user)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
