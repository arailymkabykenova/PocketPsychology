#!/usr/bin/env python3
"""
Test script to verify article generation with 3 approaches
"""

import requests
import json
import time
from datetime import datetime

# API base URL
BASE_URL = "http://localhost:8000"

def test_article_generation():
    """Test article generation for specific topics"""
    print("=== Testing Article Generation ===")
    
    # Test topics
    test_topics = ["любовь", "love", "выгорание", "burnout"]
    
    for topic in test_topics:
        print(f"\n--- Testing article generation for topic: '{topic}' ---")
        
        try:
            # Generate articles for topic
            response = requests.post(f"{BASE_URL}/content/generate?content_type=article&topic={topic}&language=ru")
            if response.status_code == 200:
                result = response.json()
                articles = result.get("content", [])
                print(f"✅ Generated {len(articles)} articles for topic '{topic}'")
                
                # Check approaches
                approaches = [article.get("approach", "unknown") for article in articles]
                print(f"   Approaches: {approaches}")
                
                if len(articles) == 3:
                    print(f"   ✅ Success: Generated exactly 3 articles")
                else:
                    print(f"   ⚠️  Warning: Generated {len(articles)} articles, expected 3")
                
                # Check if articles have different approaches
                unique_approaches = set(approaches)
                if len(unique_approaches) == 3:
                    print(f"   ✅ Success: All 3 approaches present: {unique_approaches}")
                else:
                    print(f"   ⚠️  Warning: Only {len(unique_approaches)} unique approaches: {unique_approaches}")
                
            else:
                print(f"❌ Failed to generate articles: {response.status_code}")
                print(f"   Response: {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
        
        # Wait between tests
        time.sleep(2)

def test_article_retrieval():
    """Test article retrieval for specific topics"""
    print("\n=== Testing Article Retrieval ===")
    
    # Test topics
    test_topics = ["любовь", "love", "выгорание", "burnout"]
    
    for topic in test_topics:
        print(f"\n--- Testing article retrieval for topic: '{topic}' ---")
        
        try:
            # Get articles for topic
            response = requests.get(f"{BASE_URL}/content/articles?topic={topic}&language=ru")
            if response.status_code == 200:
                result = response.json()
                articles = result.get("articles", [])
                print(f"✅ Retrieved {len(articles)} articles for topic '{topic}'")
                
                # Check approaches
                approaches = [article.get("approach", "unknown") for article in articles]
                print(f"   Approaches: {approaches}")
                
                if len(articles) >= 3:
                    print(f"   ✅ Success: Retrieved {len(articles)} articles")
                else:
                    print(f"   ⚠️  Warning: Retrieved {len(articles)} articles, expected 3")
                
            else:
                print(f"❌ Failed to retrieve articles: {response.status_code}")
                print(f"   Response: {response.text}")
                
        except Exception as e:
            print(f"❌ Error: {e}")
        
        # Wait between tests
        time.sleep(1)

if __name__ == "__main__":
    print(f"Starting article generation tests at {datetime.now()}")
    print(f"API Base URL: {BASE_URL}")
    
    # Test article generation
    test_article_generation()
    
    # Test article retrieval
    test_article_retrieval()
    
    print(f"\n=== Tests completed at {datetime.now()} ===") 