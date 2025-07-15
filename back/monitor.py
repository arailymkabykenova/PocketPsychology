#!/usr/bin/env python3
"""
System monitoring for Chatbot
"""

import os
import sys
import time
import json
import logging
import requests
import sqlite3
import redis
from datetime import datetime, timedelta
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('monitor.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class SystemMonitor:
    """Monitors system health and performance"""
    
    def __init__(self):
        self.db_path = "chatbot.db"
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.api_url = "http://localhost:8000"
        self.stats_file = "system_stats.json"
        
    def check_database(self):
        """Check database health and size"""
        try:
            if not os.path.exists(self.db_path):
                return {"status": "error", "message": "Database file not found"}
            
            size = os.path.getsize(self.db_path)
            size_mb = size / (1024 * 1024)
            
            # Check database integrity
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute("PRAGMA integrity_check")
                integrity = cursor.fetchone()[0]
                
                # Get table counts
                cursor.execute("SELECT COUNT(*) FROM conversations")
                conversations_count = cursor.fetchone()[0]
                
                cursor.execute("SELECT COUNT(*) FROM topics")
                topics_count = cursor.fetchone()[0]
                
                cursor.execute("SELECT COUNT(*) FROM generated_content")
                content_count = cursor.fetchone()[0]
            
            return {
                "status": "healthy" if integrity == "ok" else "warning",
                "size_mb": round(size_mb, 2),
                "integrity": integrity,
                "conversations": conversations_count,
                "topics": topics_count,
                "content": content_count
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def check_redis(self):
        """Check Redis health and memory usage"""
        try:
            self.redis_client.ping()
            
            info = self.redis_client.info()
            used_memory_mb = info['used_memory'] / (1024 * 1024)
            connected_clients = info['connected_clients']
            
            # Get key count
            keys_count = len(self.redis_client.keys("*"))
            
            return {
                "status": "healthy",
                "memory_mb": round(used_memory_mb, 2),
                "clients": connected_clients,
                "keys": keys_count
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def check_api(self):
        """Check API health"""
        try:
            response = requests.get(f"{self.api_url}/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                return {
                    "status": "healthy",
                    "response_time": response.elapsed.total_seconds(),
                    "services": data.get("environment", {})
                }
            else:
                return {"status": "warning", "status_code": response.status_code}
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def check_celery(self):
        """Check Celery worker status"""
        try:
            # Check if Celery processes are running
            import psutil
            
            celery_processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                try:
                    if 'celery' in proc.info['name'].lower() or \
                       any('celery' in str(cmd).lower() for cmd in proc.info['cmdline'] or []):
                        celery_processes.append({
                            "pid": proc.info['pid'],
                            "name": proc.info['name'],
                            "memory_mb": round(proc.memory_info().rss / (1024 * 1024), 2)
                        })
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            return {
                "status": "healthy" if celery_processes else "warning",
                "workers": len(celery_processes),
                "processes": celery_processes
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def get_system_stats(self):
        """Get comprehensive system statistics"""
        stats = {
            "timestamp": datetime.now().isoformat(),
            "database": self.check_database(),
            "redis": self.check_redis(),
            "api": self.check_api(),
            "celery": self.check_celery()
        }
        
        # Calculate overall health
        overall_status = "healthy"
        for component, data in stats.items():
            if component != "timestamp" and data.get("status") == "error":
                overall_status = "error"
                break
            elif component != "timestamp" and data.get("status") == "warning":
                overall_status = "warning"
        
        stats["overall_status"] = overall_status
        return stats
    
    def save_stats(self, stats):
        """Save statistics to file"""
        try:
            with open(self.stats_file, 'w') as f:
                json.dump(stats, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save stats: {e}")
    
    def load_stats(self):
        """Load previous statistics"""
        try:
            if os.path.exists(self.stats_file):
                with open(self.stats_file, 'r') as f:
                    return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load stats: {e}")
        return None
    
    def check_alerts(self, stats):
        """Check for alert conditions"""
        alerts = []
        
        # Database size alert
        if stats["database"]["status"] == "healthy":
            size_mb = stats["database"]["size_mb"]
            if size_mb > 100:  # Alert if > 100MB
                alerts.append(f"Database size is large: {size_mb}MB")
        
        # Redis memory alert
        if stats["redis"]["status"] == "healthy":
            memory_mb = stats["redis"]["memory_mb"]
            if memory_mb > 50:  # Alert if > 50MB
                alerts.append(f"Redis memory usage is high: {memory_mb}MB")
        
        # API response time alert
        if stats["api"]["status"] == "healthy":
            response_time = stats["api"]["response_time"]
            if response_time > 2:  # Alert if > 2 seconds
                alerts.append(f"API response time is slow: {response_time}s")
        
        # Celery workers alert
        if stats["celery"]["status"] == "healthy":
            workers = stats["celery"]["workers"]
            if workers == 0:
                alerts.append("No Celery workers running")
            elif workers > 5:
                alerts.append(f"Too many Celery workers: {workers}")
        
        return alerts
    
    def print_status(self, stats):
        """Print formatted status"""
        print("\n" + "=" * 60)
        print(f"🤖 System Status: {stats['overall_status'].upper()}")
        print(f"📅 Time: {stats['timestamp']}")
        print("=" * 60)
        
        # Database
        db = stats["database"]
        print(f"🗄️ Database: {db['status']}")
        if db['status'] == "healthy":
            print(f"   Size: {db['size_mb']}MB")
            print(f"   Conversations: {db['conversations']}")
            print(f"   Topics: {db['topics']}")
            print(f"   Content: {db['content']}")
        else:
            print(f"   Error: {db.get('message', 'Unknown error')}")
        
        # Redis
        redis = stats["redis"]
        print(f"🚀 Redis: {redis['status']}")
        if redis['status'] == "healthy":
            print(f"   Memory: {redis['memory_mb']}MB")
            print(f"   Clients: {redis['clients']}")
            print(f"   Keys: {redis['keys']}")
        else:
            print(f"   Error: {redis.get('message', 'Unknown error')}")
        
        # API
        api = stats["api"]
        print(f"🌐 API: {api['status']}")
        if api['status'] == "healthy":
            print(f"   Response time: {api['response_time']}s")
        else:
            print(f"   Error: {api.get('message', 'Unknown error')}")
        
        # Celery
        celery = stats["celery"]
        print(f"⚡ Celery: {celery['status']}")
        if celery['status'] == "healthy":
            print(f"   Workers: {celery['workers']}")
            for proc in celery['processes']:
                print(f"   - PID {proc['pid']}: {proc['memory_mb']}MB")
        else:
            print(f"   Error: {celery.get('message', 'Unknown error')}")
        
        # Alerts
        alerts = self.check_alerts(stats)
        if alerts:
            print("\n⚠️ ALERTS:")
            for alert in alerts:
                print(f"   • {alert}")
        
        print("=" * 60)

def main():
    """Main monitoring loop"""
    print("📊 Starting System Monitor...")
    
    monitor = SystemMonitor()
    
    try:
        while True:
            # Get current stats
            stats = monitor.get_system_stats()
            
            # Save stats
            monitor.save_stats(stats)
            
            # Print status
            monitor.print_status(stats)
            
            # Wait before next check
            time.sleep(60)  # Check every minute
            
    except KeyboardInterrupt:
        print("\n🛑 Monitoring stopped")

if __name__ == "__main__":
    main() 