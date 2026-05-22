"""
Tests for tracker CRUD endpoints.
DB and auth are mocked — no real PostgreSQL required.
"""
import uuid
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.auth import get_current_user
from app.database import get_db
from app.main import app
from app.models.tracker import Tracker
from app.models.user import User

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

FAKE_USER_ID = uuid.uuid4()
FAKE_TRACKER_ID = uuid.uuid4()


def _fake_user() -> MagicMock:
    u = MagicMock(spec=User)
    u.id = FAKE_USER_ID
    return u


def _fake_tracker() -> MagicMock:
    t = MagicMock(spec=Tracker)
    t.id = FAKE_TRACKER_ID
    t.user_id = FAKE_USER_ID
    t.url = "https://example.com/product"
    t.name = "Test Tracker"
    t.css_selector = "span.price"
    t.currency_symbol = "$"
    t.target_price = Decimal("99.99")
    t.target_direction = "below"
    t.status = "active"
    t.last_price = Decimal("120.00")
    t.last_checked_at = None
    t.created_at = __import__("datetime").datetime(2026, 1, 1, tzinfo=__import__("datetime").timezone.utc)
    return t


def _mock_db_empty() -> AsyncMock:
    session = AsyncMock()
    result = MagicMock()
    result.scalars.return_value.all.return_value = []
    session.execute.return_value = result
    return session


def _mock_db_with_tracker(tracker: MagicMock) -> AsyncMock:
    session = AsyncMock()

    scalar_result = MagicMock()
    scalar_result.scalar_one_or_none.return_value = tracker
    scalar_result.scalars.return_value.all.return_value = [tracker]

    session.execute.return_value = scalar_result
    session.commit = AsyncMock()

    async def fake_refresh(obj):
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


def _override_auth(user: MagicMock):
    async def _get_user():
        return user

    app.dependency_overrides[get_current_user] = _get_user


def _override_db(session: AsyncMock):
    async def _get_session():
        yield session

    app.dependency_overrides[get_db] = _get_session


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_list_trackers_empty():
    _override_auth(_fake_user())
    _override_db(_mock_db_empty())

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/trackers", headers={"Authorization": "Bearer fake"})

    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_create_tracker_returns_201():
    tracker = _fake_tracker()
    session = AsyncMock()
    session.add = MagicMock()
    session.commit = AsyncMock()

    # After refresh, populate the tracker's attributes
    async def fake_refresh(obj):
        obj.id = tracker.id
        obj.user_id = tracker.user_id
        obj.url = tracker.url
        obj.name = tracker.name
        obj.css_selector = tracker.css_selector
        obj.currency_symbol = tracker.currency_symbol
        obj.target_price = tracker.target_price
        obj.target_direction = tracker.target_direction
        obj.status = tracker.status
        obj.last_price = tracker.last_price
        obj.last_checked_at = tracker.last_checked_at
        obj.created_at = tracker.created_at

    session.refresh.side_effect = fake_refresh

    _override_auth(_fake_user())
    _override_db(session)

    payload = {
        "url": "https://example.com/product",
        "name": "Test Tracker",
        "css_selector": "span.price",
        "xpath": "//span[@class='price']",
        "currency_symbol": "$",
        "confirmed_price": "120.00",
        "target_price": "99.99",
        "target_direction": "below",
    }

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/trackers", json=payload, headers={"Authorization": "Bearer fake"}
        )

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Tracker"
    assert data["target_direction"] == "below"


@pytest.mark.asyncio
async def test_delete_tracker_not_owned_returns_404():
    other_user = MagicMock(spec=User)
    other_user.id = uuid.uuid4()  # different user

    session = AsyncMock()
    scalar_result = MagicMock()
    scalar_result.scalar_one_or_none.return_value = None  # not found for this user
    session.execute.return_value = scalar_result

    _override_auth(other_user)
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(
            f"/trackers/{FAKE_TRACKER_ID}", headers={"Authorization": "Bearer fake"}
        )

    assert response.status_code == 404
