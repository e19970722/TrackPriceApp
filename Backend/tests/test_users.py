"""
Tests for user profile endpoints.
DB and auth are mocked — no real PostgreSQL required.
"""
import uuid
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.auth import get_current_user
from app.database import get_db
from app.main import app
from app.models.user import User

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

FAKE_USER_ID = uuid.uuid4()


def _fake_user() -> MagicMock:
    u = MagicMock(spec=User)
    u.id = FAKE_USER_ID
    u.email = "test@example.com"
    u.subscription_tier = "free"
    u.auth_provider = "apple"
    u.apns_token = None
    return u


def _mock_db(user: MagicMock) -> AsyncMock:
    session = AsyncMock()
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
async def test_get_me_returns_user():
    user = _fake_user()
    _override_auth(user)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/users/me", headers={"Authorization": "Bearer fake"})

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(FAKE_USER_ID)
    assert data["email"] == "test@example.com"
    assert data["subscription_tier"] == "free"
    assert data["auth_provider"] == "apple"


@pytest.mark.asyncio
async def test_patch_me_updates_apns_token():
    user = _fake_user()
    session = _mock_db(user)
    _override_auth(user)
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            "/users/me",
            json={"apns_token": "device-token-123"},
            headers={"Authorization": "Bearer fake"},
        )

    assert response.status_code == 200
    assert user.apns_token == "device-token-123"
    session.commit.assert_awaited_once()
    session.refresh.assert_awaited_once_with(user)
