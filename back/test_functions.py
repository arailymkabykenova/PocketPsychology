#!/usr/bin/env python3
"""
Test script for backend functions directly
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from tasks import get_cached_topic, _check_if_topics_are_similar
from ai_service import AIService
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_get_cached_topic():
    """Test get_cached_topic function"""
    print("🔍 Testing get_cached_topic function...")
    
    # Test with non-existent user
    topic = get_cached_topic("non_existent_user")
    print(f"Non-existent user topic: {topic}")
    
    # Test with test user
    topic = get_cached_topic("test_user_123")
    print(f"Test user topic: {topic}")
    
    return topic

def test_topic_similarity():
    """Test topic similarity function"""
    print("\n🎯 Testing topic similarity function...")
    
    try:
        # Initialize AI service
        ai_service = AIService()
        
        # Test similar topics
        similar_topics = [
            ("стресс", "тревога"),
            ("рабочий стресс", "давление на работе"),
            ("проблемы в отношениях", "семейные проблемы"),
            ("stress", "anxiety"),
            ("work stress", "job pressure")
        ]
        
        for topic1, topic2 in similar_topics:
            result = _check_if_topics_are_similar(topic1, topic2, "ru" if "стресс" in topic1 else "en")
            print(f"'{topic1}' vs '{topic2}': {'Similar' if not result else 'Different'}")
        
        # Test different topics
        different_topics = [
            ("стресс", "мотивация"),
            ("тревога", "карьера"),
            ("stress", "motivation"),
            ("anxiety", "career")
        ]
        
        print("\nTesting different topics:")
        for topic1, topic2 in different_topics:
            result = _check_if_topics_are_similar(topic1, topic2, "ru" if "стресс" in topic1 else "en")
            print(f"'{topic1}' vs '{topic2}': {'Similar' if not result else 'Different'}")
            
    except Exception as e:
        print(f"❌ Error testing topic similarity: {e}")

def main():
    """Run function tests"""
    print("🚀 Starting function tests...")
    print("=" * 50)
    
    # Test get_cached_topic
    test_get_cached_topic()
    
    # Test topic similarity
    test_topic_similarity()
    
    print("\n" + "=" * 50)
    print("✅ Function tests completed!")

if __name__ == "__main__":
    main() 