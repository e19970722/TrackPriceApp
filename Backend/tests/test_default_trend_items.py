"""
Real-DB tests for the seeded global "On Trend" items and the clone endpoint.

These run against the actual PostgreSQL test database (no DB mocking). Each test
runs inside an outer transaction that is rolled back on teardown, so any writes
(including the repository's own ``commit()`` calls, which are re-scoped to
SAVEPOINTs) never persist. The seed rows themselves come from the Alembic
migration ``b7c8d9e0f1a2`` and are expected to already exist in the DB.
"""
from __future__ import annotations

import uuid
from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import event, select
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import NullPool

from app.auth import get_current_user
from app.config import settings
from app.database import get_db
from app.main import app
from app.models.tracker import Tracker
from app.models.user import User
from app.seed_data import SEED_ITEMS, SEED_TRACKER_IDS

pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """A session whose writes roll back at the end of the test.

    Everything runs inside a single outer transaction on a dedicated connection;
    the app's ``commit()`` calls are converted into (and restarted as) SAVEPOINTs
    so route handlers behave normally without persisting anything.

    A fresh ``NullPool`` engine is created per test so nothing is shared across
    pytest-asyncio's per-test event loops.
    """
    test_engine = create_async_engine(settings.DATABASE_URL, poolclass=NullPool)
    connection = await test_engine.connect()
    trans = await connection.begin()
    session_factory = async_sessionmaker(bind=connection, expire_on_commit=False)
    session = session_factory()

    await connection.begin_nested()

    @event.listens_for(session.sync_session, "after_transaction_end")
    def _restart_savepoint(sess, transaction):  # type: ignore[no-untyped-def]
        if transaction.nested and not transaction._parent.nested:
            sess.begin_nested()

    try:
        yield session
    finally:
        await session.close()
        await trans.rollback()
        await connection.close()
        await test_engine.dispose()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def _get_db() -> AsyncGenerator[AsyncSession, None]:
        yield db_session

    app.dependency_overrides[get_db] = _get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def fresh_user(db_session: AsyncSession) -> User:
    """A brand-new user with no trackers of their own."""
    user = User(
        id=uuid.uuid4(),
        auth_provider="dev",
        auth_provider_id=f"test-{uuid.uuid4()}",
        email="fresh@test.local",
    )
    db_session.add(user)
    await db_session.flush()
    return user


def _override_auth(user: User) -> None:
    async def _get_user() -> User:
        return user

    app.dependency_overrides[get_current_user] = _get_user


# ---------------------------------------------------------------------------
# Seed items appear in GLOBAL trends, even for a user with no trackers.
# ---------------------------------------------------------------------------


async def test_seed_items_appear_in_trends_for_fresh_user(
    client: AsyncClient, fresh_user: User
) -> None:
    _override_auth(fresh_user)

    response = await client.get("/trackers/trends", headers={"Authorization": "Bearer x"})

    assert response.status_code == 200
    trends = response.json()
    returned_ids = {t["tracker_id"] for t in trends}
    for item in SEED_ITEMS:
        assert str(item.tracker_id) in returned_ids, f"missing seed {item.name}"


async def test_each_seed_item_has_non_zero_delta(
    client: AsyncClient, fresh_user: User
) -> None:
    _override_auth(fresh_user)

    response = await client.get("/trackers/trends", headers={"Authorization": "Bearer x"})

    assert response.status_code == 200
    by_id = {t["tracker_id"]: t for t in response.json()}
    for item in SEED_ITEMS:
        trend = by_id[str(item.tracker_id)]
        assert trend["delta_percent"] > 0
        assert trend["direction"] == "down"  # baseline > current for every seed
        assert trend["current_price"] == pytest.approx(float(item.current_price))


# ---------------------------------------------------------------------------
# POST /trackers/trends/{tracker_id}/track — clone a seed into a user tracker.
# ---------------------------------------------------------------------------


async def test_track_seed_creates_user_owned_tracker(
    client: AsyncClient, fresh_user: User, db_session: AsyncSession
) -> None:
    _override_auth(fresh_user)
    seed = SEED_ITEMS[0]

    response = await client.post(
        f"/trackers/trends/{seed.tracker_id}/track",
        headers={"Authorization": "Bearer x"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["user_id"] == str(fresh_user.id)
    assert body["id"] != str(seed.tracker_id)  # a NEW tracker, not the seed
    assert body["url"] == seed.url
    assert body["name"] == seed.name
    assert body["item_name"] == seed.item_name
    assert body["currency_symbol"] == seed.currency_symbol
    assert body["target_direction"] == "below"
    assert body["target_price"] == pytest.approx(float(seed.current_price))

    # It is genuinely persisted under the current user.
    rows = await db_session.execute(
        select(Tracker).where(Tracker.user_id == fresh_user.id)
    )
    owned = list(rows.scalars().all())
    assert len(owned) == 1
    assert owned[0].id == uuid.UUID(body["id"])


async def test_track_seed_allows_duplicates(
    client: AsyncClient, fresh_user: User
) -> None:
    _override_auth(fresh_user)
    seed = SEED_ITEMS[1]
    headers = {"Authorization": "Bearer x"}
    url = f"/trackers/trends/{seed.tracker_id}/track"

    first = await client.post(url, headers=headers)
    second = await client.post(url, headers=headers)

    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["id"] != second.json()["id"]


async def test_track_unknown_tracker_returns_404(
    client: AsyncClient, fresh_user: User
) -> None:
    _override_auth(fresh_user)

    response = await client.post(
        f"/trackers/trends/{uuid.uuid4()}/track",
        headers={"Authorization": "Bearer x"},
    )

    assert response.status_code == 404


async def test_seed_ids_are_stable() -> None:
    # Guards against accidental drift between seed_data and the three items.
    assert len(SEED_ITEMS) == 3
    assert {i.tracker_id for i in SEED_ITEMS} == SEED_TRACKER_IDS
