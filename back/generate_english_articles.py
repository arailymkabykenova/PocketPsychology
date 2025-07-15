#!/usr/bin/env python3
"""
Script to generate English articles
"""

import os
import sys
from dotenv import load_dotenv
from content_generator import ContentGenerator
from ai_service import AIService
from database import Database

# Load environment variables
load_dotenv()

def generate_english_articles():
    """Generate English articles for common topics"""
    try:
        # Initialize services
        ai_service = AIService()
        db = Database()
        content_generator = ContentGenerator(db, ai_service)
        
        # Common psychological topics in English
        english_topics = [
            "stress", "anxiety", "depression", "confidence", "motivation", 
            "relationships", "self-esteem", "work-life balance", "mindfulness",
            "sleep", "exercise", "meditation", "goal setting", "time management"
        ]
        
        print("Generating English articles...")
        
        for topic in english_topics:
            print(f"Generating article for topic: {topic}")
            
            # Create topic dict
            topic_dict = {"topic": topic, "frequency": 1}
            
            # Generate article
            article = content_generator._generate_article(topic_dict, language="en")
            
            if article:
                # Save to database
                db.save_generated_content(
                    content_type="article",
                    title=article["title"],
                    content=article["content"],
                    source_topics=[topic]
                )
                print(f"✅ Generated article: {article['title']}")
            else:
                print(f"❌ Failed to generate article for topic: {topic}")
        
        print("English article generation completed!")
        
    except Exception as e:
        print(f"Error generating English articles: {e}")

if __name__ == "__main__":
    generate_english_articles() 