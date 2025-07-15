import os
from celery import Celery
from dotenv import load_dotenv

load_dotenv()

# Redis configuration
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Create Celery instance
celery_app = Celery(
    "chatbot",
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=["tasks"]
)

# Celery configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes
    task_soft_time_limit=25 * 60,  # 25 minutes
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
)

# Optional: Configure periodic tasks
celery_app.conf.beat_schedule = {
    # Убираем автоматическую генерацию startup content
    # "initialize-startup-content": {
    #     "task": "tasks.initialize_startup_content",
    #     "schedule": 60.0,  # Run once after 1 minute of startup
    # },
    "generate-daily-content": {
        "task": "tasks.generate_daily_content",
        "schedule": 1800.0,  # Every 30 minutes
    },
    "generate-content-for-all-topics": {
        "task": "tasks.generate_content_for_all_topics",
        "schedule": 3600.0,  # Every hour
    },
    "update-popular-topics": {
        "task": "tasks.update_popular_topics",
        "schedule": 900.0,  # Every 15 minutes
    },
    "cleanup-old-content": {
        "task": "tasks.cleanup_old_content",
        "schedule": 86400.0,  # Every day
    },
} 