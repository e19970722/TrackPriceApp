"""
Pure alert evaluation logic — no DB access, no async, no side effects.

This module is intentionally dependency-free so it can be unit-tested without
any infrastructure.
"""
from datetime import datetime, timedelta
from decimal import Decimal


def should_alert(tracker, new_price: Decimal, now: datetime) -> bool:
    """Return True if a push notification should be sent for *tracker*.

    Rules (in order):
    1. Tracker must be active.
    2. Price must have crossed the target threshold in the configured direction.
    3. At least 24 hours must have passed since the last notification.
    4. The new price must be a more extreme value than the last notified price
       (i.e. lower for "below" targets, higher for "above" targets).
    """
    if tracker.status != "active":
        return False

    if tracker.target_direction == "below":
        if new_price > tracker.target_price:
            return False
    else:  # "above"
        if new_price < tracker.target_price:
            return False

    # 24-hour throttle
    if tracker.last_notified_at is not None:
        if (now - tracker.last_notified_at) < timedelta(hours=24):
            return False

    # Re-notify guard: only alert on a new price extreme past the threshold
    if tracker.last_notified_price is not None:
        last = Decimal(str(tracker.last_notified_price))
        if tracker.target_direction == "below":
            if new_price >= last:
                return False
        else:
            if new_price <= last:
                return False

    return True
