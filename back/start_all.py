#!/usr/bin/env python3
"""
Script to start the entire chatbot system
"""

import os
import sys
import subprocess
import time
import signal
import threading
from pathlib import Path

def check_redis():
    """Check if Redis is running"""
    try:
        import redis
        r = redis.Redis(host='localhost', port=6379, db=0)
        r.ping()
        print("✅ Redis is running")
        return True
    except Exception as e:
        print(f"❌ Redis is not running: {e}")
        return False

def start_redis():
    """Start Redis if not running"""
    if check_redis():
        return
    
    print("🚀 Starting Redis...")
    try:
        # Try to start Redis using system command
        subprocess.run(["redis-server", "--daemonize", "yes"], check=True)
        time.sleep(2)
        if check_redis():
            print("✅ Redis started successfully")
        else:
            print("❌ Failed to start Redis")
            print("Please install and start Redis manually:")
            print("  macOS: brew install redis && brew services start redis")
            print("  Ubuntu: sudo apt install redis-server && sudo systemctl start redis-server")
            sys.exit(1)
    except FileNotFoundError:
        print("❌ Redis not found. Please install Redis first:")
        print("  macOS: brew install redis")
        print("  Ubuntu: sudo apt install redis-server")
        sys.exit(1)

def start_celery_worker():
    """Start Celery worker"""
    print("🚀 Starting Celery worker...")
    try:
        process = subprocess.Popen([
            sys.executable, "start_celery.py"
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(3)
        if process.poll() is None:
            print("✅ Celery worker started")
            return process
        else:
            print("❌ Failed to start Celery worker")
            return None
    except Exception as e:
        print(f"❌ Error starting Celery worker: {e}")
        return None

def start_celery_beat():
    """Start Celery beat scheduler"""
    print("🚀 Starting Celery beat...")
    try:
        process = subprocess.Popen([
            sys.executable, "start_celery_beat.py"
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(3)
        if process.poll() is None:
            print("✅ Celery beat started")
            return process
        else:
            print("❌ Failed to start Celery beat")
            return None
    except Exception as e:
        print(f"❌ Error starting Celery beat: {e}")
        return None

def start_fastapi():
    """Start FastAPI server"""
    print("🚀 Starting FastAPI server...")
    try:
        process = subprocess.Popen([
            sys.executable, "main.py"
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(3)
        if process.poll() is None:
            print("✅ FastAPI server started")
            return process
        else:
            print("❌ Failed to start FastAPI server")
            return None
    except Exception as e:
        print(f"❌ Error starting FastAPI server: {e}")
        return None

def start_flower():
    """Start Flower monitoring"""
    print("🚀 Starting Flower monitoring...")
    try:
        process = subprocess.Popen([
            sys.executable, "-m", "celery", "-A", "celery_app", "flower", "--port=5555"
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(3)
        if process.poll() is None:
            print("✅ Flower monitoring started at http://localhost:5555")
            return process
        else:
            print("❌ Failed to start Flower")
            return None
    except Exception as e:
        print(f"❌ Error starting Flower: {e}")
        return None

def cleanup(processes):
    """Cleanup function to stop all processes"""
    print("\n🛑 Stopping all processes...")
    for process in processes:
        if process and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()

def main():
    """Main function to start all services"""
    print("🤖 Starting Chatbot System...")
    print("=" * 50)
    
    # Change to script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Check and start Redis
    start_redis()
    
    # Start all services
    processes = []
    
    # Start Celery worker
    worker_process = start_celery_worker()
    if worker_process:
        processes.append(worker_process)
    
    # Start Celery beat
    beat_process = start_celery_beat()
    if beat_process:
        processes.append(beat_process)
    
    # Start FastAPI server
    api_process = start_fastapi()
    if api_process:
        processes.append(api_process)
    
    # Start Flower (optional)
    flower_process = start_flower()
    if flower_process:
        processes.append(flower_process)
    
    print("\n" + "=" * 50)
    print("🎉 System started successfully!")
    print("\nServices:")
    print("  • FastAPI Server: http://localhost:8000")
    print("  • API Documentation: http://localhost:8000/docs")
    print("  • Flower Monitoring: http://localhost:5555")
    print("\nPress Ctrl+C to stop all services")
    print("=" * 50)
    
    # Set up signal handler for graceful shutdown
    def signal_handler(signum, frame):
        cleanup(processes)
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Keep main thread alive
    try:
        while True:
            time.sleep(1)
            # Check if any process has died
            for i, process in enumerate(processes):
                if process and process.poll() is not None:
                    print(f"⚠️  Process {i} has stopped unexpectedly")
    except KeyboardInterrupt:
        cleanup(processes)

if __name__ == "__main__":
    main() 