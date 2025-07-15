#!/usr/bin/env python3
"""
Simple test for topic extraction
"""

import redis
import json
import time
from tasks import get_cached_topic, extract_topic_from_message

# Test Redis connection
r = redis.Redis(host='localhost', port=6379, db=0)

print("🧪 Testing topic extraction...")

# Test 1: Check if we can get cached topic
user_id = "test_user_123"
cached_topic = get_cached_topic(user_id)
print(f"✅ Cached topic for {user_id}: '{cached_topic}'")

# Test 2: Extract new topic
message = "Я чувствую тревогу и беспокойство"
user_id_new = "test_user_new_789"

print(f"📝 Extracting topic from: '{message}'")
result = extract_topic_from_message(message, user_id_new, "ru")
print(f"✅ Extraction result: {json.dumps(result, indent=2, ensure_ascii=False)}")

# Test 3: Check if topic was cached
time.sleep(2)  # Wait a bit for task to complete
cached_topic_new = get_cached_topic(user_id_new)
print(f"✅ New cached topic: '{cached_topic_new}'")

print("🎉 Test completed!") 