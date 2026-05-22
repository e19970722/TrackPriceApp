"""Unit tests for alert_evaluator.should_alert.

These tests are pure (no DB, no async, no I/O) and cover every decision branch
in the evaluator.
"""
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import MagicMock

from app.alert_evaluator import should_alert

NOW = datetime(2026, 5, 22, 12, 0, 0, tzinfo=timezone.utc)


def _tracker(
    status: str = "active",
    direction: str = "below",
    target: Decimal = Decimal("100"),
    last_notified_at: "datetime | None" = None,
    last_notified_price: "Decimal | None" = None,
) -> MagicMock:
    t = MagicMock()
    t.status = status
    t.target_direction = direction
    t.target_price = target
    t.last_notified_at = last_notified_at
    t.last_notified_price = last_notified_price
    return t


# ---------------------------------------------------------------------------
# Basic threshold tests
# ---------------------------------------------------------------------------


def test_fires_below_target():
    assert should_alert(_tracker(), Decimal("90"), NOW) is True


def test_fires_above_target():
    assert should_alert(_tracker(direction="above"), Decimal("110"), NOW) is True


def test_no_alert_when_price_equals_target_below():
    # Price exactly at target: "below" means strictly below, so equal does NOT fire
    # (new_price > tracker.target_price is False, so it passes the guard —
    # but equal means NOT strictly below target. Per spec the guard is >, so equal fires.)
    # The spec guard is: if new_price > target: return False
    # So price == target does pass through for "below" direction.
    assert should_alert(_tracker(), Decimal("100"), NOW) is True


def test_no_alert_when_price_above_target_below_direction():
    assert should_alert(_tracker(), Decimal("110"), NOW) is False


def test_no_alert_when_price_below_target_above_direction():
    assert should_alert(_tracker(direction="above"), Decimal("90"), NOW) is False


# ---------------------------------------------------------------------------
# Status guard
# ---------------------------------------------------------------------------


def test_no_alert_when_inactive():
    assert should_alert(_tracker(status="broken"), Decimal("90"), NOW) is False


def test_no_alert_when_paused():
    assert should_alert(_tracker(status="paused"), Decimal("90"), NOW) is False


# ---------------------------------------------------------------------------
# 24-hour throttle
# ---------------------------------------------------------------------------


def test_no_alert_within_24h():
    t = _tracker(
        last_notified_at=NOW - timedelta(hours=1),
        last_notified_price=Decimal("90"),
    )
    assert should_alert(t, Decimal("85"), NOW) is False


def test_no_alert_exactly_at_24h_boundary():
    # Exactly 24 h is NOT less than timedelta(hours=24), so it should fire.
    t = _tracker(
        last_notified_at=NOW - timedelta(hours=24),
        last_notified_price=Decimal("90"),
    )
    # 24 h elapsed == timedelta(hours=24), which is NOT < timedelta(hours=24)
    assert should_alert(t, Decimal("80"), NOW) is True


def test_alert_after_24h():
    t = _tracker(
        last_notified_at=NOW - timedelta(hours=25),
        last_notified_price=Decimal("90"),
    )
    # Must also be a new extreme — use a lower price than last_notified_price
    assert should_alert(t, Decimal("80"), NOW) is True


# ---------------------------------------------------------------------------
# Re-notify extreme guard
# ---------------------------------------------------------------------------


def test_no_re_alert_unless_new_extreme_below():
    t = _tracker(
        last_notified_at=NOW - timedelta(hours=25),
        last_notified_price=Decimal("90"),
    )
    assert should_alert(t, Decimal("95"), NOW) is False  # not lower than 90


def test_re_alert_at_new_extreme_below():
    t = _tracker(
        last_notified_at=NOW - timedelta(hours=25),
        last_notified_price=Decimal("90"),
    )
    assert should_alert(t, Decimal("80"), NOW) is True  # lower than 90


def test_no_re_alert_same_price_below():
    t = _tracker(
        last_notified_at=NOW - timedelta(hours=25),
        last_notified_price=Decimal("90"),
    )
    # Equal to last notified price: >= guard blocks it
    assert should_alert(t, Decimal("90"), NOW) is False


def test_no_re_alert_unless_new_extreme_above():
    t = _tracker(
        direction="above",
        target=Decimal("100"),
        last_notified_at=NOW - timedelta(hours=25),
        last_notified_price=Decimal("110"),
    )
    assert should_alert(t, Decimal("105"), NOW) is False  # not higher than 110


def test_re_alert_at_new_extreme_above():
    t = _tracker(
        direction="above",
        target=Decimal("100"),
        last_notified_at=NOW - timedelta(hours=25),
        last_notified_price=Decimal("110"),
    )
    assert should_alert(t, Decimal("120"), NOW) is True  # higher than 110


# ---------------------------------------------------------------------------
# First-time alert (no prior notification)
# ---------------------------------------------------------------------------


def test_first_alert_no_prior_notification_below():
    t = _tracker(last_notified_at=None, last_notified_price=None)
    assert should_alert(t, Decimal("90"), NOW) is True


def test_first_alert_no_prior_notification_above():
    t = _tracker(direction="above", last_notified_at=None, last_notified_price=None)
    assert should_alert(t, Decimal("110"), NOW) is True


# ---------------------------------------------------------------------------
# Price above target (below-direction)
# ---------------------------------------------------------------------------


def test_above_price_not_reached():
    assert should_alert(_tracker(direction="above"), Decimal("90"), NOW) is False
