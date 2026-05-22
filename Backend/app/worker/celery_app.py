from celery import Celery

from app.config import settings

celery = Celery(
    "trackprice",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=[
        "app.worker.scraper",
        "app.worker.scheduler",
        "app.worker.sync_url_jobs",
        "app.worker.failure_handler",
    ],
)
celery.conf.task_serializer = "json"
celery.conf.result_serializer = "json"
celery.conf.timezone = "UTC"
celery.conf.beat_schedule = {
    "dispatch-due-scrapes": {
        "task": "app.worker.scheduler.dispatch_due_scrapes",
        "schedule": 60.0,
    },
    "check-broken-trackers": {
        "task": "app.worker.failure_handler.check_broken_trackers",
        "schedule": 3600.0,
    },
}
