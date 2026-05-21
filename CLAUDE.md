# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrackPriceApp is a native iOS price tracker. Users open a WebView, long-press to activate selection mode, tap a price element on any webpage, and set a target price. The backend scrapes that element on a schedule and sends a push notification when the price crosses the threshold.

See `SPEC.md` for the full product specification.

## Architecture

Two components:

### `iOS/` — Native iOS app (Swift + SwiftUI, iOS 16+)
- WKWebView browser with injected `ElementPicker.js` for element selection
- Charts framework for price history graphs
- APNs / FCM for push notifications
- Apple Sign In + Google Sign In

### `Backend/` — Python API + scraping workers
- **FastAPI** — REST API
- **PostgreSQL** — users, trackers, price snapshots, url_jobs
- **Redis + Celery** — job queue; Celery Beat for scheduling
- **Playwright** + residential proxy pool — headless scraping

## Key Design Decisions

- **URL-level deduplication**: one fetch per URL per check window, results fanned out to all trackers watching that URL (`url_jobs` table).
- **Selector failure**: silent retry for 3 days, then notify user to re-select or provide a new URL.
- **Alert throttle**: max 1 push per tracker per 24 hours; re-notify only when price reaches a new extreme past the threshold.
- **Tiers**: free = 10 trackers + daily checks; paid = unlimited + hourly. Paywall not enforced yet — `subscription_tier` column exists for future use.

## Commands

_To be filled in as each component is scaffolded._

### Backend
```bash
# Install dependencies (once virtualenv is created)
pip install -r requirements.txt

# Run dev server
uvicorn app.main:app --reload

# Run Celery worker
celery -A app.worker worker --loglevel=info

# Run Celery Beat scheduler
celery -A app.worker beat --loglevel=info

# Run tests
pytest

# Run a single test
pytest tests/path/to/test_file.py::test_function_name
```

### iOS
Open `iOS/TrackPriceApp.xcodeproj` in Xcode. Build and run with `Cmd+R`. Tests: `Cmd+U`.
