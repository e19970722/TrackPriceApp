# Backend/CLAUDE.md

Guidance for agents working inside the `Backend/` directory.

## What this component does

Python API + scraping workers. FastAPI serves the REST API consumed by the iOS app. PostgreSQL stores users, trackers, price snapshots, and url_jobs. Celery Beat schedules periodic scraping jobs; Celery workers execute them using Playwright against a residential proxy pool. When a price threshold is crossed, `alert_evaluator.py` triggers `push_sender.py` to dispatch APNs / FCM notifications.

## Stack

| Layer | Technology |
|---|---|
| API | FastAPI (Python 3.12) |
| Database | PostgreSQL via SQLAlchemy (async) |
| Migrations | Alembic |
| Queue / Scheduler | Redis + Celery + Celery Beat |
| Scraping | Playwright + residential proxy pool |
| Auth | JWT (python-jose) |
| Push | APNs HTTP/2 + FCM |

## Directory Layout

```
Backend/
├── app/
│   ├── main.py              # FastAPI app factory, router registration
│   ├── config.py            # Settings (pydantic-settings, reads .env)
│   ├── database.py          # Async SQLAlchemy engine + session factory
│   ├── auth.py              # JWT helpers, current_user dependency
│   ├── alert_evaluator.py   # Price-threshold logic
│   ├── push_sender.py       # APNs / FCM dispatch
│   ├── api/                 # FastAPI routers (one file per resource)
│   ├── models/              # SQLAlchemy ORM models
│   ├── schemas/             # Pydantic request/response schemas
│   ├── repositories/        # DB query layer (no business logic)
│   ├── services/            # Business logic (calls repositories)
│   └── worker/              # Celery app + task definitions
├── alembic/                 # Migration scripts
├── tests/                   # pytest test suite
├── pyproject.toml           # Ruff + mypy config
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```

## Commands

```bash
# Install dependencies
pip install -r requirements.txt

# Run dev server (hot-reload)
uvicorn app.main:app --reload

# Run Celery worker
celery -A app.worker worker --loglevel=info

# Run Celery Beat scheduler
celery -A app.worker beat --loglevel=info

# Run all tests
pytest

# Run a single test
pytest tests/path/to/test_file.py::test_function_name

# Lint (Ruff)
ruff check .

# Type-check
mypy app/
```

## Tooling

- **Ruff**: line-length 100, rules E + F + I (errors, pyflakes, isort)
- **mypy**: strict mode off; `ignore_missing_imports = true`, target Python 3.12

## Key Design Decisions

- **URL-level deduplication**: one Playwright fetch per URL per check window; results fan out to all trackers watching that URL via the `url_jobs` table. Never fire a separate request per tracker.
- **Selector failure**: silent retry for 3 days, then notify user to re-select element or provide a new URL.
- **Alert throttle**: max 1 push notification per tracker per 24 hours; re-notify only when the price reaches a new extreme beyond the threshold.
- **Tiers**: free = 10 trackers + daily checks; paid = unlimited + hourly. `subscription_tier` column exists but paywall is not yet enforced.

## Coding Conventions

- Keep routers thin: validate input, call a service, return a schema. No DB queries in routers.
- Repositories own all SQL; services own all business logic. Never skip a layer.
- Use async SQLAlchemy sessions throughout (`async with session_factory() as session`).
- New endpoints need a corresponding pytest test — even a smoke test is enough.
- Do not use `try/except Exception` to swallow errors silently; let FastAPI's exception handlers do their job, or raise `HTTPException` explicitly.
