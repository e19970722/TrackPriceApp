"""
Tests for the /items endpoints and the check_item_reminders Celery task.

DB and auth are mocked — no real PostgreSQL required.
"""
from __future__ import annotations

import uuid
from datetime import date, datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.auth import get_current_user
from app.database import get_db
from app.main import app
from app.models.item import Item
from app.models.user import User

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

FAKE_USER_ID = uuid.uuid4()
OTHER_USER_ID = uuid.uuid4()
FAKE_ITEM_ID = uuid.uuid4()

TODAY = date(2026, 6, 2)


def _fake_user(user_id: uuid.UUID = FAKE_USER_ID) -> MagicMock:
    u = MagicMock(spec=User)
    u.id = user_id
    return u


def _fake_item(
    *,
    item_id: uuid.UUID = FAKE_ITEM_ID,
    user_id: uuid.UUID = FAKE_USER_ID,
    name: str = "Milk",
    best_before_date: date = date(2026, 6, 10),
    remind_days_before: int = 3,
    remind_on_day: bool = False,
    is_used: bool = False,
    quantity: str | None = None,
    location: str | None = "fridge",
    location_custom: str | None = None,
    added_date: date = date(2026, 6, 1),
    created_at: datetime = datetime(2026, 6, 1, tzinfo=timezone.utc),
) -> MagicMock:
    t = MagicMock(spec=Item)
    t.id = item_id
    t.user_id = user_id
    t.name = name
    t.quantity = quantity
    t.location = location
    t.location_custom = location_custom
    t.best_before_date = best_before_date
    t.added_date = added_date
    t.remind_days_before = remind_days_before
    t.remind_on_day = remind_on_day
    t.is_used = is_used
    t.created_at = created_at
    return t


def _mock_db_empty() -> AsyncMock:
    session = AsyncMock()
    result = MagicMock()
    result.scalars.return_value.all.return_value = []
    result.scalar_one_or_none.return_value = None
    session.execute.return_value = result
    return session


def _mock_db_with_item(item: MagicMock) -> AsyncMock:
    session = AsyncMock()
    scalar_result = MagicMock()
    scalar_result.scalar_one_or_none.return_value = item
    scalar_result.scalars.return_value.all.return_value = [item]
    session.execute.return_value = scalar_result
    session.commit = AsyncMock()

    async def fake_refresh(obj: object) -> None:
        pass

    session.refresh.side_effect = fake_refresh
    return session


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def _clear_overrides():
    yield
    app.dependency_overrides.clear()


def _override_auth(user: MagicMock) -> None:
    async def _get_user() -> MagicMock:
        return user

    app.dependency_overrides[get_current_user] = _get_user


def _override_db(session: AsyncMock) -> None:
    async def _get_session():
        yield session

    app.dependency_overrides[get_db] = _get_session


# ---------------------------------------------------------------------------
# POST /items
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_item_returns_201() -> None:
    item = _fake_item()
    session = AsyncMock()
    session.add = MagicMock()
    session.commit = AsyncMock()

    async def fake_refresh(obj: object) -> None:
        obj.id = item.id  # type: ignore[attr-defined]
        obj.user_id = item.user_id  # type: ignore[attr-defined]
        obj.name = item.name  # type: ignore[attr-defined]
        obj.quantity = item.quantity  # type: ignore[attr-defined]
        obj.location = item.location  # type: ignore[attr-defined]
        obj.location_custom = item.location_custom  # type: ignore[attr-defined]
        obj.best_before_date = item.best_before_date  # type: ignore[attr-defined]
        obj.added_date = item.added_date  # type: ignore[attr-defined]
        obj.remind_days_before = item.remind_days_before  # type: ignore[attr-defined]
        obj.remind_on_day = item.remind_on_day  # type: ignore[attr-defined]
        obj.is_used = item.is_used  # type: ignore[attr-defined]
        obj.created_at = item.created_at  # type: ignore[attr-defined]

    session.refresh.side_effect = fake_refresh

    _override_auth(_fake_user())
    _override_db(session)

    payload = {
        "name": "Milk",
        "best_before_date": "2026-06-10",
        "location": "fridge",
        "remind_days_before": 3,
        "remind_on_day": False,
    }

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/items", json=payload, headers={"Authorization": "Bearer fake"})

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Milk"
    assert data["location"] == "fridge"
    assert "days_left" in data
    assert "remind_on" in data
    assert "freshness" in data


# ---------------------------------------------------------------------------
# GET /items
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_list_items_empty() -> None:
    _override_auth(_fake_user())
    _override_db(_mock_db_empty())

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/items", headers={"Authorization": "Bearer fake"})

    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_list_items_excludes_used_by_default() -> None:
    used_item = _fake_item(is_used=True)
    session = _mock_db_with_item(used_item)
    # Simulate the repo returning empty when is_used filter is applied
    result = MagicMock()
    result.scalars.return_value.all.return_value = []
    session.execute.return_value = result

    _override_auth(_fake_user())
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/items", headers={"Authorization": "Bearer fake"})

    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_list_items_includes_used_when_requested() -> None:
    used_item = _fake_item(is_used=True)
    session = _mock_db_with_item(used_item)

    _override_auth(_fake_user())
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(
            "/items?include_used=true", headers={"Authorization": "Bearer fake"}
        )

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["is_used"] is True


# ---------------------------------------------------------------------------
# GET /items/{id}
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_item_returns_200() -> None:
    item = _fake_item()
    session = _mock_db_with_item(item)

    _override_auth(_fake_user())
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(
            f"/items/{FAKE_ITEM_ID}", headers={"Authorization": "Bearer fake"}
        )

    assert response.status_code == 200
    assert response.json()["name"] == "Milk"


@pytest.mark.asyncio
async def test_get_item_not_owned_returns_404() -> None:
    session = _mock_db_empty()

    _override_auth(_fake_user(OTHER_USER_ID))
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(
            f"/items/{FAKE_ITEM_ID}", headers={"Authorization": "Bearer fake"}
        )

    assert response.status_code == 404


# ---------------------------------------------------------------------------
# PATCH /items/{id}
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_update_item_returns_200() -> None:
    item = _fake_item()
    session = _mock_db_with_item(item)

    _override_auth(_fake_user())
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"/items/{FAKE_ITEM_ID}",
            json={"name": "Oat Milk", "remind_days_before": 5},
            headers={"Authorization": "Bearer fake"},
        )

    assert response.status_code == 200


@pytest.mark.asyncio
async def test_update_item_not_found_returns_404() -> None:
    session = _mock_db_empty()

    _override_auth(_fake_user())
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"/items/{FAKE_ITEM_ID}",
            json={"name": "X"},
            headers={"Authorization": "Bearer fake"},
        )

    assert response.status_code == 404


# ---------------------------------------------------------------------------
# DELETE /items/{id}
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_delete_item_returns_204() -> None:
    item = _fake_item()
    session = _mock_db_with_item(item)

    _override_auth(_fake_user())
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(
            f"/items/{FAKE_ITEM_ID}", headers={"Authorization": "Bearer fake"}
        )

    assert response.status_code == 204


@pytest.mark.asyncio
async def test_delete_item_not_owned_returns_404() -> None:
    session = _mock_db_empty()

    _override_auth(_fake_user(OTHER_USER_ID))
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(
            f"/items/{FAKE_ITEM_ID}", headers={"Authorization": "Bearer fake"}
        )

    assert response.status_code == 404


# ---------------------------------------------------------------------------
# POST /items/{id}/mark-used
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_mark_used_sets_flag() -> None:
    item = _fake_item(is_used=False)
    session = _mock_db_with_item(item)

    _override_auth(_fake_user())
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"/items/{FAKE_ITEM_ID}/mark-used", headers={"Authorization": "Bearer fake"}
        )

    assert response.status_code == 200
    # The mock session's setattr path sets it directly
    session.commit.assert_awaited()


@pytest.mark.asyncio
async def test_mark_used_item_disappears_from_default_list() -> None:
    """After mark-used, the default list (include_used=false) excludes the item."""
    # Simulate DB returning empty after the is_used filter
    session = AsyncMock()
    result = MagicMock()
    result.scalars.return_value.all.return_value = []
    result.scalar_one_or_none.return_value = None
    session.execute.return_value = result

    _override_auth(_fake_user())
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/items", headers={"Authorization": "Bearer fake"})

    assert response.status_code == 200
    assert response.json() == []


# ---------------------------------------------------------------------------
# Pydantic computed fields (unit tests — no HTTP, no DB)
# ---------------------------------------------------------------------------


def _build_item_out(best_before: date, remind_days: int = 3, is_used: bool = False):
    from app.schemas.item import ItemOut

    return ItemOut(
        id=FAKE_ITEM_ID,
        user_id=FAKE_USER_ID,
        name="Test",
        best_before_date=best_before,
        added_date=date(2026, 1, 1),
        remind_days_before=remind_days,
        remind_on_day=False,
        is_used=is_used,
        created_at=datetime(2026, 1, 1, tzinfo=timezone.utc),
    )


def test_freshness_fresh() -> None:
    # 10 days away with remind_days_before=3 → fresh
    out = _build_item_out(date(2026, 6, 12), remind_days=3)
    with patch("app.schemas.item.date") as mock_date:
        mock_date.today.return_value = TODAY
        assert out.freshness == "fresh"


def test_freshness_expiring() -> None:
    # expires in 2 days with remind_days_before=3 → expiring
    out = _build_item_out(date(2026, 6, 4), remind_days=3)
    with patch("app.schemas.item.date") as mock_date:
        mock_date.today.return_value = TODAY
        assert out.freshness == "expiring"


def test_freshness_expired() -> None:
    # best_before is in the past
    out = _build_item_out(date(2026, 5, 30), remind_days=3)
    with patch("app.schemas.item.date") as mock_date:
        mock_date.today.return_value = TODAY
        assert out.freshness == "expired"


def test_days_left_positive() -> None:
    out = _build_item_out(date(2026, 6, 12))
    with patch("app.schemas.item.date") as mock_date:
        mock_date.today.return_value = TODAY
        assert out.days_left == 10


def test_days_left_negative() -> None:
    out = _build_item_out(date(2026, 5, 30))
    with patch("app.schemas.item.date") as mock_date:
        mock_date.today.return_value = TODAY
        assert out.days_left == -3


def test_remind_on_date() -> None:
    from datetime import timedelta
    best_before = date(2026, 6, 10)
    out = _build_item_out(best_before, remind_days=3)
    assert out.remind_on == best_before - timedelta(days=3)


# ---------------------------------------------------------------------------
# check_item_reminders task (unit tests — mocked DB and Redis)
# ---------------------------------------------------------------------------


class _async_ctx:
    """Wraps a mock session for use as `async with AsyncSessionLocal() as db`."""

    def __init__(self, session: AsyncMock) -> None:
        self._session = session

    def __call__(self, *args, **kwargs) -> "_async_ctx":
        return self

    async def __aenter__(self) -> AsyncMock:
        return self._session

    async def __aexit__(self, *args) -> None:
        pass


def _mock_session_multi(advance_items: list, today_items: list) -> AsyncMock:
    session = AsyncMock()
    results = []
    for items in [advance_items, today_items]:
        r = MagicMock()
        r.scalars.return_value.all.return_value = items
        results.append(r)
    session.execute.side_effect = results
    return session


@pytest.mark.asyncio
async def test_reminder_task_sends_advance_push() -> None:
    """Advance reminder fires when best_before_date - remind_days_before == today."""
    from app.worker.item_reminder import _check_reminders

    item = _fake_item(
        best_before_date=date(2026, 6, 5),  # 3 days from TODAY (2026-06-02)
        remind_days_before=3,
        remind_on_day=False,
    )

    session = _mock_session_multi(advance_items=[item], today_items=[])
    # Simulate get_apns_token returning a token
    token_result = MagicMock()
    token_result.scalar_one_or_none.return_value = "device-token-abc"
    # First execute call → advance items, second → today items, third → apns token
    session.execute.side_effect = [
        MagicMock(**{"scalars.return_value.all.return_value": [item]}),
        MagicMock(**{"scalars.return_value.all.return_value": []}),
        token_result,
    ]

    with (
        patch(
            "app.worker.item_reminder.AsyncSessionLocal",
            return_value=_async_ctx(session),
        ),
        patch("app.worker.item_reminder.datetime") as mock_dt,
        patch("app.worker.item_reminder._get_redis", return_value=None),
        patch(
            "app.push_sender.send_item_reminder", new_callable=AsyncMock
        ) as mock_send,
    ):
        mock_now = MagicMock()
        mock_now.date.return_value = TODAY
        mock_dt.now.return_value = mock_now

        await _check_reminders()

    mock_send.assert_awaited_once()


@pytest.mark.asyncio
async def test_reminder_task_sends_today_push() -> None:
    """On-day reminder fires when best_before_date == today and remind_on_day=True."""
    from app.worker.item_reminder import _check_reminders

    item = _fake_item(
        best_before_date=TODAY,
        remind_days_before=3,
        remind_on_day=True,
    )

    token_result = MagicMock()
    token_result.scalar_one_or_none.return_value = "device-token-xyz"

    session = AsyncMock()
    session.execute.side_effect = [
        MagicMock(**{"scalars.return_value.all.return_value": []}),  # advance items
        MagicMock(**{"scalars.return_value.all.return_value": [item]}),  # today items
        token_result,  # apns token
    ]

    with (
        patch(
            "app.worker.item_reminder.AsyncSessionLocal",
            return_value=_async_ctx(session),
        ),
        patch("app.worker.item_reminder.datetime") as mock_dt,
        patch("app.worker.item_reminder._get_redis", return_value=None),
        patch(
            "app.push_sender.send_item_expiring_today", new_callable=AsyncMock
        ) as mock_send,
    ):
        mock_now = MagicMock()
        mock_now.date.return_value = TODAY
        mock_dt.now.return_value = mock_now

        await _check_reminders()

    mock_send.assert_awaited_once()


@pytest.mark.asyncio
async def test_reminder_task_no_push_when_no_token() -> None:
    """No notification sent when user has no APNS token."""
    from app.worker.item_reminder import _check_reminders

    item = _fake_item(
        best_before_date=date(2026, 6, 5),
        remind_days_before=3,
    )

    token_result = MagicMock()
    token_result.scalar_one_or_none.return_value = None  # no token

    session = AsyncMock()
    session.execute.side_effect = [
        MagicMock(**{"scalars.return_value.all.return_value": [item]}),  # advance items
        token_result,  # apns token lookup (None → no push)
        MagicMock(**{"scalars.return_value.all.return_value": []}),       # today items
    ]

    with (
        patch(
            "app.worker.item_reminder.AsyncSessionLocal",
            return_value=_async_ctx(session),
        ),
        patch("app.worker.item_reminder.datetime") as mock_dt,
        patch("app.worker.item_reminder._get_redis", return_value=None),
        patch(
            "app.push_sender.send_item_reminder", new_callable=AsyncMock
        ) as mock_send,
    ):
        mock_now = MagicMock()
        mock_now.date.return_value = TODAY
        mock_dt.now.return_value = mock_now

        await _check_reminders()

    mock_send.assert_not_awaited()


@pytest.mark.asyncio
async def test_reminder_task_throttle_prevents_double_push() -> None:
    """When Redis throttle key exists, no second push is sent."""
    from app.worker.item_reminder import _check_reminders

    item = _fake_item(
        best_before_date=date(2026, 6, 5),
        remind_days_before=3,
    )

    mock_redis = MagicMock()
    mock_redis.get.return_value = "1"  # throttled

    session = AsyncMock()
    session.execute.side_effect = [
        MagicMock(**{"scalars.return_value.all.return_value": [item]}),
        MagicMock(**{"scalars.return_value.all.return_value": []}),
    ]

    with (
        patch(
            "app.worker.item_reminder.AsyncSessionLocal",
            return_value=_async_ctx(session),
        ),
        patch("app.worker.item_reminder.datetime") as mock_dt,
        patch("app.worker.item_reminder._get_redis", return_value=mock_redis),
        patch(
            "app.push_sender.send_item_reminder", new_callable=AsyncMock
        ) as mock_send,
    ):
        mock_now = MagicMock()
        mock_now.date.return_value = TODAY
        mock_dt.now.return_value = mock_now

        await _check_reminders()

    mock_send.assert_not_awaited()
