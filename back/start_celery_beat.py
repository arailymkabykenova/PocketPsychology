#!/usr/bin/env python3
"""
Script to start Celery beat scheduler for the chatbot application
"""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from celery_app import celery_app

if __name__ == "__main__":
    # Start Celery beat scheduler
    celery_app.start([
        "beat",
        "--loglevel=info",
        "--scheduler=celery.beat.PersistentScheduler",  # Persistent scheduler
    ]) 