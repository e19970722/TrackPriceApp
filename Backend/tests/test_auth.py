"""
Tests for /auth/apple and /auth/google endpoints.

The DB dependency is overridden with a mock so no real PostgreSQL is required.
jwt.get_unverified_claims is patched to return controlled claim payloads.
"""
import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.database import get_db
from app.main import app
from app.models.user import User

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

FAKE_USER_ID = uuid.uuid4()


def _make_fake_user(provider: str, provider_id: str, email: str) -> MagicMock:
    user = MagicMock(spec=User)
    user.id = FAKE_USER_ID
    user.auth_provider = provider
    user.auth_provider_id = provider_id
    user.email = email
    user.subscription_tier = "free"
    return user


def _mock_db_session(fake_user: User) -> AsyncMock:
    """Return an AsyncMock that mimics an AsyncSession performing an upsert."""
    session = AsyncMock()

    # First call: scalar_one_or_none() returns None  → triggers INSERT path
    # We configure it to return the fake user after commit/refresh
    scalar_result = MagicMock()
    scalar_result.scalar_one_or_none.return_value = None
    session.execute.return_value = scalar_result
    session.commit = AsyncMock()

    async def fake_refresh(obj):
        # Simulate DB populating the id after INSERT
        obj.id = fake_user.id

    session.refresh.side_effect = fake_refresh
    return session


# ---------------------------------------------------------------------------
# Fixture: override get_db with an in-memory mock
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def _clear_overrides():
    """Ensure dependency overrides are cleaned up after each test."""
    yield
    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Apple Sign In tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_apple_sign_in_returns_token():
    fake_user = _make_fake_user("apple", "apple-123", "test@example.com")
    mock_session = _mock_db_session(fake_user)

    async def override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = override_get_db

    fake_claims = {"sub": "apple-123", "email": "test@example.com"}

    with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/apple", json={"token": "fake.apple.token"}
            )

    assert response.status_code == 200
    data = response.json()
    assert "token" in data
    assert isinstance(data["token"], str)
    assert len(data["token"]) > 0


@pytest.mark.asyncio
async def test_apple_sign_in_upsert_same_sub_returns_consistent_token():
    """Calling twice with the same sub should both succeed and return a token."""
    fake_user = _make_fake_user("apple", "apple-123", "test@example.com")

    fake_claims = {"sub": "apple-123", "email": "test@example.com"}

    tokens = []
    for _ in range(2):
        mock_session = _mock_db_session(fake_user)

        async def override_get_db():
            yield mock_session

        app.dependency_overrides[get_db] = override_get_db

        with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/auth/apple", json={"token": "fake.apple.token"}
                )

        assert response.status_code == 200
        tokens.append(response.json()["token"])

    # Both calls should return a valid JWT (not necessarily identical due to iat)
    assert all(isinstance(t, str) and len(t) > 0 for t in tokens)


@pytest.mark.asyncio
async def test_apple_sign_in_missing_sub_returns_400():
    fake_user = _make_fake_user("apple", "", "test@example.com")
    mock_session = _mock_db_session(fake_user)

    async def override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = override_get_db

    # Claims without 'sub'
    fake_claims = {"email": "test@example.com"}

    with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/apple", json={"token": "fake.apple.token"}
            )

    assert response.status_code == 400


@pytest.mark.asyncio
async def test_apple_sign_in_stores_full_name_on_create():
    """full_name from the request body is persisted as display_name on first sign-in."""
    fake_user = _make_fake_user("apple", "apple-123", "test@example.com")
    mock_session = _mock_db_session(fake_user)

    async def override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = override_get_db

    fake_claims = {"sub": "apple-123", "email": "test@example.com"}

    with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/apple",
                json={"token": "fake.apple.token", "full_name": "Sam Rivers"},
            )

    assert response.status_code == 200
    created_user = mock_session.add.call_args[0][0]
    assert created_user.display_name == "Sam Rivers"
    assert created_user.email == "test@example.com"


@pytest.mark.asyncio
async def test_apple_sign_in_backfills_display_name_when_null():
    """An existing user with display_name=None gets it backfilled on re-sign-in."""
    existing_user = _make_fake_user("apple", "apple-123", "test@example.com")
    existing_user.display_name = None

    session = AsyncMock()
    scalar_result = MagicMock()
    scalar_result.scalar_one_or_none.return_value = existing_user
    session.execute.return_value = scalar_result
    session.commit = AsyncMock()

    async def fake_refresh(obj):
        pass

    session.refresh.side_effect = fake_refresh

    async def override_get_db():
        yield session

    app.dependency_overrides[get_db] = override_get_db

    fake_claims = {"sub": "apple-123", "email": "test@example.com"}

    with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/apple",
                json={"token": "fake.apple.token", "full_name": "Sam Rivers"},
            )

    assert response.status_code == 200
    assert existing_user.display_name == "Sam Rivers"
    session.add.assert_not_called()
    session.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_apple_sign_in_does_not_overwrite_existing_display_name():
    existing_user = _make_fake_user("apple", "apple-123", "test@example.com")
    existing_user.display_name = "Original Name"

    session = AsyncMock()
    scalar_result = MagicMock()
    scalar_result.scalar_one_or_none.return_value = existing_user
    session.execute.return_value = scalar_result
    session.commit = AsyncMock()

    async def override_get_db():
        yield session

    app.dependency_overrides[get_db] = override_get_db

    fake_claims = {"sub": "apple-123", "email": "test@example.com"}

    with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/apple",
                json={"token": "fake.apple.token", "full_name": "Different Name"},
            )

    assert response.status_code == 200
    assert existing_user.display_name == "Original Name"
    session.commit.assert_not_awaited()


# ---------------------------------------------------------------------------
# Google Sign In tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_google_sign_in_returns_token():
    fake_user = _make_fake_user("google", "google-456", "guser@gmail.com")
    mock_session = _mock_db_session(fake_user)

    async def override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = override_get_db

    fake_claims = {"sub": "google-456", "email": "guser@gmail.com"}

    with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/google", json={"token": "fake.google.token"}
            )

    assert response.status_code == 200
    data = response.json()
    assert "token" in data
    assert isinstance(data["token"], str)


@pytest.mark.asyncio
async def test_google_sign_in_stores_name_claim_on_create():
    """The Google `name` claim is persisted as display_name on first sign-in."""
    fake_user = _make_fake_user("google", "google-456", "guser@gmail.com")
    mock_session = _mock_db_session(fake_user)

    async def override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = override_get_db

    fake_claims = {"sub": "google-456", "email": "guser@gmail.com", "name": "G User"}

    with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/google", json={"token": "fake.google.token"}
            )

    assert response.status_code == 200
    created_user = mock_session.add.call_args[0][0]
    assert created_user.display_name == "G User"


@pytest.mark.asyncio
async def test_google_sign_in_missing_sub_returns_400():
    fake_user = _make_fake_user("google", "", "guser@gmail.com")
    mock_session = _mock_db_session(fake_user)

    async def override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = override_get_db

    fake_claims = {"email": "guser@gmail.com"}

    with patch("app.api.auth.jwt.get_unverified_claims", return_value=fake_claims):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/google", json={"token": "fake.google.token"}
            )

    assert response.status_code == 400
