#!/usr/bin/env python3
"""
Script for automatic content generation based on conversation topics.
Can be run manually or scheduled with cron.
"""

import os
import sys
import logging
from datetime import datetime
from dotenv import load_dotenv

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import Database
from ai_service import AIService
from content_generator import ContentGenerator

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('content_generation.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def main():
    """Main function for content generation"""
    try:
        logger.info("Starting content generation process")
        
        # Initialize services
        ai_service = AIService()
        content_generator = ContentGenerator(ai_service.db, ai_service)
        
        logger.info("Services initialized successfully")
        
        # Generate content
        result = content_generator.schedule_content_generation()
        
        if "error" in result:
            logger.error(f"Content generation failed: {result['error']}")
            return 1
        
        logger.info(f"Content generation completed successfully:")
        logger.info(f"- Articles generated: {result['articles_generated']}")
        logger.info(f"- Videos generated: {result['videos_generated']}")
        
        # Get some stats
        topics = ai_service.db.get_popular_topics(limit=5)
        logger.info(f"Top 5 popular topics: {[t['topic'] for t in topics]}")
        
        return 0
        
    except Exception as e:
        logger.error(f"Unexpected error in content generation: {str(e)}")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code) 