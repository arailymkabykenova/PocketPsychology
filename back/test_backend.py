#!/usr/bin/env python3
"""
Test script for backend functionality
"""

import requests
import json
import time
from datetime import datetime

# Backend URL (adjust if needed)
BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("🔍 Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print("✅ Health check passed")
            print(f"   AI Service: {data.get('ai_service', 'unknown')}")
            print(f"   Redis: {data.get('redis', {}).get('status', 'unknown')}")
            print(f"   Celery: {data.get('celery', 'unknown')}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_chat():
    """Test chat endpoint"""
    print("\n💬 Testing chat endpoint...")
    try:
        payload = {
            "message": "У меня стресс на работе",
            "mode": "support",
            "user_id": "test_user_123",
            "language": "ru"
        }
        
        response = requests.post(f"{BASE_URL}/chat", json=payload)
        if response.status_code == 200:
            data = response.json()
            print("✅ Chat request successful")
            print(f"   Response: {data.get('response', '')[:100]}...")
            print(f"   Topic: {data.get('topic', 'None')}")
            print(f"   Mode: {data.get('mode', 'None')}")
            return data
        else:
            print(f"❌ Chat request failed: {response.status_code}")
            print(f"   Error: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Chat request error: {e}")
        return None

def test_topic_extraction():
    """Test topic extraction"""
    print("\n🎯 Testing topic extraction...")
    try:
        # Test first message
        payload1 = {
            "message": "У меня стресс на работе",
            "mode": "support",
            "user_id": "test_user_topic",
            "language": "ru"
        }
        
        response1 = requests.post(f"{BASE_URL}/chat", json=payload1)
        if response1.status_code == 200:
            data1 = response1.json()
            topic1 = data1.get('topic')
            print(f"✅ First message topic: {topic1}")
            
            # Wait a bit for topic extraction
            time.sleep(2)
            
            # Test second message (same context)
            payload2 = {
                "message": "Работа очень напряженная",
                "mode": "support",
                "user_id": "test_user_topic",
                "language": "ru"
            }
            
            response2 = requests.post(f"{BASE_URL}/chat", json=payload2)
            if response2.status_code == 200:
                data2 = response2.json()
                topic2 = data2.get('topic')
                print(f"✅ Second message topic: {topic2}")
                
                # Check if topics are similar
                if topic1 == topic2:
                    print("✅ Topics are the same (good for similar context)")
                else:
                    print(f"⚠️ Topics changed: {topic1} -> {topic2}")
                
                return True
            else:
                print(f"❌ Second chat request failed: {response2.status_code}")
                return False
        else:
            print(f"❌ First chat request failed: {response1.status_code}")
            return False
    except Exception as e:
        print(f"❌ Topic extraction error: {e}")
        return False

def test_get_user_topic():
    """Test getting user topic"""
    print("\n📋 Testing get user topic...")
    try:
        user_id = "test_user_topic"
        response = requests.get(f"{BASE_URL}/user/{user_id}/topic")
        if response.status_code == 200:
            data = response.json()
            topic = data.get('topic')
            print(f"✅ User topic: {topic}")
            return topic
        else:
            print(f"❌ Get user topic failed: {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ Get user topic error: {e}")
        return None

def test_content_endpoints():
    """Test content endpoints"""
    print("\n📚 Testing content endpoints...")
    
    # Test articles
    try:
        response = requests.get(f"{BASE_URL}/content/articles?limit=3&language=ru")
        if response.status_code == 200:
            data = response.json()
            articles = data.get('articles', [])
            print(f"✅ Articles endpoint: {len(articles)} articles")
        else:
            print(f"❌ Articles endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Articles endpoint error: {e}")
    
    # Test quotes
    try:
        response = requests.get(f"{BASE_URL}/content/daily-quote?language=ru")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Quotes endpoint: {data.get('text', '')[:50]}...")
        else:
            print(f"❌ Quotes endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Quotes endpoint error: {e}")

def main():
    """Run all tests"""
    print("🚀 Starting backend tests...")
    print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)
    
    # Test health
    if not test_health():
        print("❌ Health check failed, stopping tests")
        return
    
    # Test chat
    chat_result = test_chat()
    if not chat_result:
        print("❌ Chat test failed, stopping tests")
        return
    
    # Test topic extraction
    test_topic_extraction()
    
    # Test get user topic
    test_get_user_topic()
    
    # Test content endpoints
    test_content_endpoints()
    
    print("\n" + "=" * 50)
    print("✅ All tests completed!")

if __name__ == "__main__":
    main() 