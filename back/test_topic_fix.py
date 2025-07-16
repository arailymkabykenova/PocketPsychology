#!/usr/bin/env python3
"""
Test script to verify topic extraction and article generation fixes
"""

import requests
import json
import time
from datetime import datetime

# API base URL
BASE_URL = "http://localhost:8000"

def test_topic_extraction():
    """Test that topic extraction works correctly without delay"""
    print("=== Testing Topic Extraction ===")
    
    # Test user ID
    user_id = "test_user_topic_fix"
    
    # Test messages with different topics
    test_messages = [
        "Я очень люблю свою девушку, но боюсь потерять её",
        "У меня выгорание на работе, не знаю что делать",
        "Хочу найти мотивацию для занятий спортом"
    ]
    
    for i, message in enumerate(test_messages, 1):
        print(f"\n--- Test {i}: '{message}' ---")
        
        # Send chat request
        chat_data = {
            "message": message,
            "mode": "analysis",
            "user_id": user_id,
            "language": "ru"
        }
        
        try:
            response = requests.post(f"{BASE_URL}/chat", json=chat_data)
            if response.status_code == 200:
                result = response.json()
                topic = result.get("topic")
                print(f"✅ Chat response received")
                print(f"   Topic: {topic}")
                print(f"   Topic task ID: {result.get('topic_task_id')}")
                
                # Wait for topic extraction to complete
                if result.get("topic_task_id"):
                    print("   Waiting for topic extraction...")
                    time.sleep(3)
                    
                    # Check task status
                    task_response = requests.get(f"{BASE_URL}/task/{result['topic_task_id']}/status")
                    if task_response.status_code == 200:
                        task_result = task_response.json()
                        if task_result.get("status") == "completed":
                            print(f"   ✅ Topic extraction completed: {task_result.get('result', {}).get('topic')}")
                        else:
                            print(f"   ⏳ Topic extraction status: {task_result.get('status')}")
                    else:
                        print(f"   ❌ Failed to check task status: {task_response.status_code}")
                
            else:
                print(f"❌ Chat request failed: {response.status_code}")
                print(f"   Response: {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
        
        # Wait between tests
        time.sleep(2)

def test_article_generation():
    """Test that 3 articles are generated per topic"""
    print("\n=== Testing Article Generation ===")
    
    # Test topics
    test_topics = ["любовь", "выгорание", "мотивация"]
    
    for topic in test_topics:
        print(f"\n--- Testing articles for topic: '{topic}' ---")
        
        try:
            # Get articles for topic
            response = requests.get(f"{BASE_URL}/content/articles?topic={topic}&language=ru")
            if response.status_code == 200:
                result = response.json()
                articles = result.get("articles", [])
                print(f"✅ Found {len(articles)} articles for topic '{topic}'")
                
                # Check if we have 3 articles with different approaches
                approaches = [article.get("approach", "unknown") for article in articles]
                print(f"   Approaches: {approaches}")
                
                if len(articles) >= 3:
                    print(f"   ✅ Success: Found {len(articles)} articles")
                else:
                    print(f"   ⚠️  Warning: Only {len(articles)} articles found, expected 3")
                    
                    # Try to generate more articles
                    print("   Generating additional articles...")
                    gen_response = requests.post(f"{BASE_URL}/content/generate?content_type=article&topic={topic}&language=ru")
                    if gen_response.status_code == 200:
                        gen_result = gen_response.json()
                        print(f"   ✅ Generated {len(gen_result.get('content', []))} additional articles")
                    else:
                        print(f"   ❌ Failed to generate additional articles: {gen_response.status_code}")
                
            else:
                print(f"❌ Failed to get articles: {response.status_code}")
                print(f"   Response: {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
        
        # Wait between tests
        time.sleep(1)

def test_user_recommendations():
    """Test user recommendations endpoint"""
    print("\n=== Testing User Recommendations ===")
    
    user_id = "test_user_topic_fix"
    
    try:
        response = requests.get(f"{BASE_URL}/user/{user_id}/recommendations?language=ru")
        if response.status_code == 200:
            result = response.json()
            print(f"✅ User recommendations received")
            print(f"   Current topic: {result.get('current_topic')}")
            print(f"   Articles count: {len(result.get('articles', []))}")
            print(f"   Quotes count: {len(result.get('quotes', []))}")
            print(f"   Videos count: {len(result.get('videos', []))}")
        else:
            print(f"❌ Failed to get recommendations: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print(f"Starting tests at {datetime.now()}")
    print(f"API Base URL: {BASE_URL}")
    
    # Test topic extraction
    test_topic_extraction()
    
    # Test article generation
    test_article_generation()
    
    # Test user recommendations
    test_user_recommendations()
    
    print(f"\n=== Tests completed at {datetime.now()} ===") 