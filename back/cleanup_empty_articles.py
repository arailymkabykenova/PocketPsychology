#!/usr/bin/env python3
"""
Script to clean up empty articles from the database
"""

import sqlite3
import logging
from datetime import datetime

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def cleanup_empty_articles():
    """Remove articles with empty content from the database"""
    try:
        # Connect to database
        conn = sqlite3.connect('chatbot.db')
        cursor = conn.cursor()
        
        # Find articles with empty content
        cursor.execute("""
            SELECT id, title, content, source_topics, approach, created_at 
            FROM generated_content 
            WHERE content_type = 'article' 
            AND (content = ' ' OR content = '' OR content IS NULL)
        """)
        
        empty_articles = cursor.fetchall()
        
        if not empty_articles:
            logger.info("No empty articles found in database")
            return
        
        logger.info(f"Found {len(empty_articles)} empty articles to remove:")
        
        # Log articles that will be removed
        for article in empty_articles:
            article_id, title, content, source_topics, approach, created_at = article
            logger.info(f"  - ID: {article_id}, Title: {title[:50]}..., Source Topics: {source_topics}, Approach: {approach}, Created: {created_at}")
        
        # Confirm deletion
        response = input(f"\nDo you want to delete {len(empty_articles)} empty articles? (y/N): ")
        if response.lower() != 'y':
            logger.info("Deletion cancelled")
            return
        
        # Delete empty articles
        cursor.execute("""
            DELETE FROM generated_content 
            WHERE content_type = 'article' 
            AND (content = ' ' OR content = '' OR content IS NULL)
        """)
        
        deleted_count = cursor.rowcount
        conn.commit()
        
        logger.info(f"Successfully deleted {deleted_count} empty articles")
        
        # Show remaining articles count
        cursor.execute("SELECT COUNT(*) FROM generated_content WHERE content_type = 'article'")
        remaining_count = cursor.fetchone()[0]
        logger.info(f"Remaining articles in database: {remaining_count}")
        
        conn.close()
        
    except Exception as e:
        logger.error(f"Error cleaning up empty articles: {e}")
        if 'conn' in locals():
            conn.close()

def show_article_stats():
    """Show statistics about articles in the database"""
    try:
        conn = sqlite3.connect('chatbot.db')
        cursor = conn.cursor()
        
        # Total articles
        cursor.execute("SELECT COUNT(*) FROM generated_content WHERE content_type = 'article'")
        total_articles = cursor.fetchone()[0]
        
        # Articles with content
        cursor.execute("""
            SELECT COUNT(*) FROM generated_content 
            WHERE content_type = 'article' 
            AND content != ' ' AND content != '' AND content IS NOT NULL
        """)
        articles_with_content = cursor.fetchone()[0]
        
        # Empty articles
        cursor.execute("""
            SELECT COUNT(*) FROM generated_content 
            WHERE content_type = 'article' 
            AND (content = ' ' OR content = '' OR content IS NULL)
        """)
        empty_articles = cursor.fetchone()[0]
        
        # Articles by approach
        cursor.execute("""
            SELECT approach, COUNT(*) 
            FROM generated_content 
            WHERE content_type = 'article' 
            GROUP BY approach
        """)
        articles_by_approach = cursor.fetchall()
        
        # Articles by source_topics (top 10)
        cursor.execute("""
            SELECT source_topics, COUNT(*) 
            FROM generated_content 
            WHERE content_type = 'article' 
            GROUP BY source_topics 
            ORDER BY COUNT(*) DESC 
            LIMIT 10
        """)
        articles_by_source_topics = cursor.fetchall()
        
        logger.info("=== Article Statistics ===")
        logger.info(f"Total articles: {total_articles}")
        logger.info(f"Articles with content: {articles_with_content}")
        logger.info(f"Empty articles: {empty_articles}")
        
        logger.info("\n=== Articles by Approach ===")
        for approach, count in articles_by_approach:
            logger.info(f"  {approach}: {count}")
        
        logger.info("\n=== Top 10 Source Topics ===")
        for source_topics, count in articles_by_source_topics:
            logger.info(f"  {source_topics}: {count}")
        
        conn.close()
        
    except Exception as e:
        logger.error(f"Error showing article stats: {e}")
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    print("=== Article Cleanup Script ===\n")
    
    # Show current stats
    show_article_stats()
    print()
    
    # Clean up empty articles
    cleanup_empty_articles()
    
    print("\n=== Final Statistics ===")
    show_article_stats() 