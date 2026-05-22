import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_dev_token_returns_jwt():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/dev/token")
    assert response.status_code == 200
    data = response.json()
    assert "token" in data
    assert data["user_id"] == "00000000-0000-0000-0000-000000000001"


@pytest.mark.asyncio
async def test_dev_token_blocked_in_production(monkeypatch):
    import app.config as cfg
    monkeypatch.setattr(cfg.settings, "ENVIRONMENT", "production")
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/dev/token")
    assert response.status_code == 404
