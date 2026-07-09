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
    u.display_name = "Sam Rivers"
    u.subscription_tier = "free"
    u.auth_provider = "apple"
    u.apns_token = None
    u.notify_price_drops = True
    u.notify_expiring_soon = True
    u.notify_running_low = True
    u.notify_weekly_digest = False
    u.expiring_soon_days_before = 3
    u.running_low_threshold = 1
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
    assert data["display_name"] == "Sam Rivers"
    assert data["subscription_tier"] == "free"
    assert data["auth_provider"] == "apple"
    assert data["notification_preferences"] == {
        "price_drops": True,
        "expiring_soon": True,
        "running_low": True,
        "weekly_digest": False,
        "expiring_soon_days_before": 3,
        "running_low_threshold": 1,
    }
    # Flat columns must not leak into the response body.
    assert "notify_price_drops" not in data
    assert "expiring_soon_days_before" not in data
    assert "running_low_threshold" not in data


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


@pytest.mark.asyncio
async def test_patch_me_partial_notification_preferences_merge():
    """Patching one preference key leaves the others unchanged."""
    user = _fake_user()
    session = _mock_db(user)
    _override_auth(user)
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            "/users/me",
            json={"notification_preferences": {"weekly_digest": True}},
            headers={"Authorization": "Bearer fake"},
        )

    assert response.status_code == 200
    assert user.notify_weekly_digest is True
    # Omitted keys untouched
    assert user.notify_price_drops is True
    assert user.notify_expiring_soon is True
    assert user.notify_running_low is True
    data = response.json()
    assert data["notification_preferences"] == {
        "price_drops": True,
        "expiring_soon": True,
        "running_low": True,
        "weekly_digest": True,
        "expiring_soon_days_before": 3,
        "running_low_threshold": 1,
    }


@pytest.mark.asyncio
async def test_patch_me_disable_price_drops():
    user = _fake_user()
    session = _mock_db(user)
    _override_auth(user)
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            "/users/me",
            json={"notification_preferences": {"price_drops": False}},
            headers={"Authorization": "Bearer fake"},
        )

    assert response.status_code == 200
    assert user.notify_price_drops is False
    assert response.json()["notification_preferences"]["price_drops"] is False


@pytest.mark.asyncio
async def test_patch_me_apns_token_and_preferences_in_one_body():
    user = _fake_user()
    session = _mock_db(user)
    _override_auth(user)
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            "/users/me",
            json={
                "apns_token": "device-token-456",
                "notification_preferences": {"expiring_soon": False},
            },
            headers={"Authorization": "Bearer fake"},
        )

    assert response.status_code == 200
    assert user.apns_token == "device-token-456"
    assert user.notify_expiring_soon is False
    assert user.notify_price_drops is True
    data = response.json()
    assert data["notification_preferences"]["expiring_soon"] is False


@pytest.mark.asyncio
async def test_patch_me_updates_numeric_notification_settings():
    """The two int settings persist and round-trip through notification_preferences."""
    user = _fake_user()
    session = _mock_db(user)
    _override_auth(user)
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        patch_response = await client.patch(
            "/users/me",
            json={
                "notification_preferences": {
                    "expiring_soon_days_before": 7,
                    "running_low_threshold": 5,
                }
            },
            headers={"Authorization": "Bearer fake"},
        )

    assert patch_response.status_code == 200
    assert user.expiring_soon_days_before == 7
    assert user.running_low_threshold == 5
    # Other preferences untouched.
    assert user.notify_price_drops is True
    prefs = patch_response.json()["notification_preferences"]
    assert prefs["expiring_soon_days_before"] == 7
    assert prefs["running_low_threshold"] == 5

    # Round-trip through GET /users/me.
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        get_response = await client.get("/users/me", headers={"Authorization": "Bearer fake"})

    assert get_response.status_code == 200
    get_prefs = get_response.json()["notification_preferences"]
    assert get_prefs["expiring_soon_days_before"] == 7
    assert get_prefs["running_low_threshold"] == 5


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "payload",
    [
        {"expiring_soon_days_before": 0},
        {"expiring_soon_days_before": 31},
        {"running_low_threshold": 0},
        {"running_low_threshold": 100},
    ],
)
async def test_patch_me_numeric_settings_out_of_range_returns_422(payload):
    user = _fake_user()
    session = _mock_db(user)
    _override_auth(user)
    _override_db(session)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            "/users/me",
            json={"notification_preferences": payload},
            headers={"Authorization": "Bearer fake"},
        )

    assert response.status_code == 422
