"""
APNs push notification sender.

Uses HTTP/2 via httpx and ES256 JWT tokens (PyJWT) to send alerts directly to
Apple's Push Notification service without a persistent connection.
"""
import time
from decimal import Decimal

import httpx
import jwt  # PyJWT

from app.config import settings


def _make_apns_jwt() -> str:
    """Generate a short-lived ES256 JWT for APNs provider authentication."""
    now = int(time.time())
    payload = {"iss": settings.APNS_TEAM_ID, "iat": now}
    headers = {"alg": "ES256", "kid": settings.APNS_KEY_ID}
    return jwt.encode(
        payload,
        settings.APNS_PRIVATE_KEY,
        algorithm="ES256",
        headers=headers,
    )


async def send_price_alert(device_token: str, tracker, new_price: Decimal) -> None:
    """Send a price-threshold push notification to *device_token*."""
    if not device_token:
        return
    direction_word = "under" if tracker.target_direction == "below" else "over"
    body = (
        f"{tracker.name} is now {tracker.currency_symbol}{new_price:.2f} — "
        f"your target is {direction_word} "
        f"{tracker.currency_symbol}{tracker.target_price:.2f}. Tap to view."
    )
    await _send_apns(device_token, body, tracker_id=str(tracker.id))


async def send_item_reminder(device_token: str, item, days_left: int) -> None:
    """Send an advance expiry reminder push notification."""
    if not device_token:
        return
    if days_left == 0:
        body = f"{item.name} expires today!"
    elif days_left == 1:
        body = f"{item.name} expires tomorrow."
    else:
        body = f"{item.name} expires in {days_left} day{'s' if days_left != 1 else ''}."
    await _send_apns(device_token, body, tracker_id=str(item.id))


async def send_item_expiring_today(device_token: str, item) -> None:
    """Send an 'expires today' push notification."""
    if not device_token:
        return
    body = f"{item.name} expires today — use it up!"
    await _send_apns(device_token, body, tracker_id=str(item.id))


async def send_broken_alert(device_token: str, tracker) -> None:
    """Send a 'tracker broken' push notification to *device_token*."""
    if not device_token:
        return
    body = (
        f"{tracker.name} — couldn't fetch price. "
        f"Tap to provide a new URL or re-select."
    )
    await _send_apns(device_token, body, tracker_id=str(tracker.id))


async def _send_apns(device_token: str, body: str, tracker_id: str) -> None:
    """Low-level APNs HTTP/2 POST.  Silently skips if credentials are absent."""
    if not settings.APNS_KEY_ID or not settings.APNS_TEAM_ID:
        return  # credentials not configured — skip silently

    host = (
        "api.sandbox.push.apple.com"
        if settings.APNS_SANDBOX
        else "api.push.apple.com"
    )
    url = f"https://{host}/3/device/{device_token}"
    payload = {
        "aps": {"alert": body, "sound": "default"},
        "tracker_id": tracker_id,
    }
    headers = {
        "authorization": f"bearer {_make_apns_jwt()}",
        "apns-topic": settings.APNS_BUNDLE_ID,
        "apns-push-type": "alert",
    }
    async with httpx.AsyncClient(http2=True) as client:
        await client.post(url, json=payload, headers=headers, timeout=10.0)
