"""
Tests for GET /trackers/trends and the trend computation logic.
DB and auth are mocked — no real PostgreSQL required.
"""
import uuid
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.auth import get_current_user
from app.database import get_db
from app.main import app
from app.models.user import User
from app.services.tracker_service import compute_trends

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _row(
    name: str = "Tracker",
    first_price: str = "10.00",
    last_price: str = "12.00",
    snapshot_count: int = 2,
) -> SimpleNamespace:
    return SimpleNamespace(
        tracker_id=uuid.uuid4(),
        name=name,
        first_price=Decimal(first_price),
        last_price=Decimal(last_price),
        snapshot_count=snapshot_count,
    )


# ---------------------------------------------------------------------------
# compute_trends — pure logic
# ---------------------------------------------------------------------------


def test_compute_trends_upward_movement():
    trends = compute_trends([_row(name="Coffee", first_price="10.00", last_price="12.00")])

    assert len(trends) == 1
    trend = trends[0]
    assert trend.name == "Coffee"
    assert trend.direction == "up"
    assert trend.delta_percent == pytest.approx(20.0)
    assert trend.current_price == pytest.approx(12.0)


def test_compute_trends_downward_movement():
    trends = compute_trends([_row(first_price="200.00", last_price="150.00")])

    assert len(trends) == 1
    trend = trends[0]
    assert trend.direction == "down"
    assert trend.delta_percent == pytest.approx(25.0)
    assert trend.current_price == pytest.approx(150.0)


def test_compute_trends_skips_fewer_than_two_snapshots():
    trends = compute_trends([_row(snapshot_count=1)])

    assert trends == []


def test_compute_trends_skips_zero_baseline():
    trends = compute_trends([_row(first_price="0.00", last_price="5.00")])

    assert trends == []


def test_compute_trends_sorts_by_delta_desc_and_limits_to_ten():
    # Deltas of 1%..12% — expect the top 10 in descending order.
    rows = [
        _row(name=f"t{pct}", first_price="100.00", last_price=f"{100 + pct}.00")
        for pct in range(1, 13)
    ]

    trends = compute_trends(rows)

    assert len(trends) == 10
    deltas = [t.delta_percent for t in trends]
    assert deltas == sorted(deltas, reverse=True)
    assert deltas[0] == pytest.approx(12.0)
    assert deltas[-1] == pytest.approx(3.0)  # 1% and 2% fell outside the limit


# ---------------------------------------------------------------------------
# Route smoke test — /trackers/trends must not be captured by /{tracker_id}
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def _clear_overrides():
    yield
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_trends_route_not_captured_by_tracker_id():
    user = MagicMock(spec=User)
    user.id = uuid.uuid4()

    session = AsyncMock()
    result = MagicMock()
    result.all.return_value = []
    session.execute.return_value = result

    async def _get_user():
        return user

    async def _get_session():
        yield session

    app.dependency_overrides[get_current_user] = _get_user
    app.dependency_overrides[get_db] = _get_session

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/trackers/trends", headers={"Authorization": "Bearer fake"})

    # 422 would mean the dynamic /{tracker_id} route swallowed "trends".
    assert response.status_code == 200
    assert response.json() == []
