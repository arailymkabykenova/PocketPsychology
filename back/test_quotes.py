#!/usr/bin/env python3
"""
Test script for optimized content system
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

def test_daily_quote():
    """Test daily quote endpoint"""
    print("🔍 Testing daily quote...")
    try:
        response = requests.get(f"{BASE_URL}/content/daily-quote")
        if response.status_code == 200:
            quote = response.json()
            print(f"✅ Daily quote: \"{quote['text']}\" - {quote['author']}")
            return True
        else:
            print(f"❌ Failed to get daily quote: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing daily quote: {e}")
        return False

def test_get_articles():
    """Test get articles endpoint"""
    print("\n🔍 Testing get articles...")
    try:
        response = requests.get(f"{BASE_URL}/content/articles?limit=3")
        if response.status_code == 200:
            data = response.json()
            articles = data.get('articles', [])
            print(f"✅ Got {len(articles)} articles")
            for article in articles:
                print(f"   - {article['title']}")
            return True
        else:
            print(f"❌ Failed to get articles: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing get articles: {e}")
        return False

def test_get_videos():
    """Test get videos endpoint"""
    print("\n🔍 Testing get videos...")
    try:
        response = requests.get(f"{BASE_URL}/content/videos?limit=3")
        if response.status_code == 200:
            data = response.json()
            videos = data.get('videos', [])
            print(f"✅ Got {len(videos)} videos")
            for video in videos:
                print(f"   - {video['title']} ({video.get('formatted_duration', 'N/A')})")
            return True
        else:
            print(f"❌ Failed to get videos: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing get videos: {e}")
        return False

def test_get_videos_by_topic():
    """Test get videos by topic"""
    print("\n🔍 Testing get videos by topic...")
    try:
        response = requests.get(f"{BASE_URL}/content/videos?topic=мотивация&limit=2")
        if response.status_code == 200:
            data = response.json()
            videos = data.get('videos', [])
            print(f"✅ Got {len(videos)} videos for topic 'мотивация'")
            for video in videos:
                print(f"   - {video['title']}")
            return True
        else:
            print(f"❌ Failed to get videos by topic: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing get videos by topic: {e}")
        return False

def test_generate_quote():
    """Test quote generation"""
    print("\n🔍 Testing quote generation...")
    try:
        response = requests.post(f"{BASE_URL}/content/generate?content_type=quote&topic=уверенность")
        if response.status_code == 200:
            data = response.json()
            quote = data.get('content', {})
            print(f"✅ Generated quote: \"{quote.get('text', 'N/A')}\" - {quote.get('author', 'N/A')}")
            return True
        else:
            print(f"❌ Failed to generate quote: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing quote generation: {e}")
        return False

def test_generate_article():
    """Test article generation"""
    print("\n🔍 Testing article generation...")
    try:
        response = requests.post(f"{BASE_URL}/content/generate?content_type=article")
        if response.status_code == 200:
            data = response.json()
            articles = data.get('content', [])
            print(f"✅ Generated {len(articles)} articles")
            for article in articles:
                print(f"   - {article.get('title', 'N/A')}")
            return True
        else:
            print(f"❌ Failed to generate articles: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing article generation: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting optimized content system tests...")
    print(f"📅 Test time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)
    
    tests = [
        test_daily_quote,
        test_get_articles,
        test_get_videos,
        test_get_videos_by_topic,
        test_generate_quote,
        test_generate_article
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
    
    print("\n" + "=" * 50)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Content system is working correctly.")
    else:
        print("⚠️  Some tests failed. Please check the server and try again.")
    
    return passed == total

if __name__ == "__main__":
    main() 