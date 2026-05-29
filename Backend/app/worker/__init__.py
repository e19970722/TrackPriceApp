from app.worker.celery_app import celery
from app.worker.scraper import scrape_tracker

__all__ = ["celery", "scrape_tracker"]
