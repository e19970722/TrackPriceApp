from celery import Celery

from app.config import settings

celery = Celery(
    "trackprice",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["app.worker.scraper"],
)
celery.conf.task_serializer = "json"
celery.conf.result_serializer = "json"
