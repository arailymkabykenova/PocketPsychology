#!/usr/bin/env python3
"""
Script to fix article approaches in the database
"""

import sqlite3
import json
from datetime import datetime

def fix_article_approaches():
    """Fix article approaches in the database"""
    db_path = "chatbot.db"
    
    with sqlite3.connect(db_path) as conn:
        cursor = conn.cursor()
        
        # Get all articles without approach
        cursor.execute('''
            SELECT id, title, content, source_topics, created_at
            FROM generated_content
            WHERE content_type = 'article' AND is_active = 1 AND (approach IS NULL OR approach = '')
        ''')
        
        articles_without_approach = cursor.fetchall()
        print(f"Found {len(articles_without_approach)} articles without approach")
        
        if not articles_without_approach:
            print("No articles need fixing!")
            return
        
        # Update articles with default approach
        updated_count = 0
        for article in articles_without_approach:
            article_id, title, content, source_topics, created_at = article
            
            # Determine approach based on title and content
            approach = determine_approach(title, content)
            
            # Update the article
            cursor.execute('''
                UPDATE generated_content
                SET approach = ?
                WHERE id = ?
            ''', (approach, article_id))
            
            updated_count += 1
            print(f"Updated article {article_id}: '{title[:50]}...' with approach '{approach}'")
        
        conn.commit()
        print(f"\n✅ Updated {updated_count} articles with approaches")

def determine_approach(title, content):
    """Determine article approach based on title and content"""
    title_lower = title.lower()
    content_lower = content.lower()
    
    # Keywords for different approaches
    practical_keywords = [
        'практические', 'упражнения', 'техники', 'советы', 'шаги', 'методы',
        'practical', 'exercises', 'techniques', 'tips', 'steps', 'methods'
    ]
    
    theoretical_keywords = [
        'теория', 'понятие', 'объяснение', 'понимание', 'концепция', 'принципы',
        'theory', 'concept', 'explanation', 'understanding', 'principles'
    ]
    
    motivational_keywords = [
        'мотивация', 'вдохновение', 'стимул', 'энтузиазм', 'вера', 'надежда',
        'motivation', 'inspiration', 'encouragement', 'enthusiasm', 'belief', 'hope'
    ]
    
    # Check content for keywords
    practical_score = sum(1 for keyword in practical_keywords if keyword in title_lower or keyword in content_lower)
    theoretical_score = sum(1 for keyword in theoretical_keywords if keyword in title_lower or keyword in content_lower)
    motivational_score = sum(1 for keyword in motivational_keywords if keyword in title_lower or keyword in content_lower)
    
    # Return the approach with highest score, default to practical
    if theoretical_score > practical_score and theoretical_score > motivational_score:
        return "theoretical"
    elif motivational_score > practical_score and motivational_score > theoretical_score:
        return "motivational"
    else:
        return "practical"

def check_article_distribution():
    """Check the distribution of articles by approach"""
    db_path = "chatbot.db"
    
    with sqlite3.connect(db_path) as conn:
        cursor = conn.cursor()
        
        # Get article distribution by approach
        cursor.execute('''
            SELECT approach, COUNT(*) as count
            FROM generated_content
            WHERE content_type = 'article' AND is_active = 1
            GROUP BY approach
            ORDER BY count DESC
        ''')
        
        distribution = cursor.fetchall()
        print("\n=== Article Distribution by Approach ===")
        for approach, count in distribution:
            print(f"{approach or 'NULL'}: {count} articles")
        
        # Get article distribution by topic and approach
        cursor.execute('''
            SELECT source_topics, approach, COUNT(*) as count
            FROM generated_content
            WHERE content_type = 'article' AND is_active = 1
            GROUP BY source_topics, approach
            ORDER BY count DESC
            LIMIT 10
        ''')
        
        topic_distribution = cursor.fetchall()
        print("\n=== Top 10 Topic-Approach Combinations ===")
        for source_topics, approach, count in topic_distribution:
            topics = json.loads(source_topics) if source_topics else []
            topic_name = topics[0] if topics else "unknown"
            print(f"{topic_name} ({approach or 'NULL'}): {count} articles")

if __name__ == "__main__":
    print(f"Starting article approach fix at {datetime.now()}")
    
    # Check current distribution
    check_article_distribution()
    
    # Fix articles without approach
    fix_article_approaches()
    
    # Check distribution after fix
    check_article_distribution()
    
    print(f"\n✅ Article approach fix completed at {datetime.now()}") 