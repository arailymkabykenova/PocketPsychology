#!/usr/bin/env python3
"""
Automated startup script for the chatbot system
This script starts all required services in the correct order
"""

import subprocess
import time
import os
import sys
from pathlib import Path

def run_command(command, description, background=False):
    """Run a command and handle errors"""
    print(f"🔄 {description}...")
    
    if background:
        try:
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            print(f"✅ {description} started (PID: {process.pid})")
            return process
        except Exception as e:
            print(f"❌ Failed to start {description}: {e}")
            return None
    else:
        try:
            result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
            print(f"✅ {description} completed successfully")
            return result
        except subprocess.CalledProcessError as e:
            print(f"❌ {description} failed: {e}")
            print(f"Error output: {e.stderr}")
            return None

def check_service(service_name, check_command):
    """Check if a service is running"""
    try:
        result = subprocess.run(check_command, shell=True, capture_output=True, text=True)
        return result.returncode == 0
    except:
        return False

def main():
    print("🚀 Starting Chatbot System...")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not Path("main.py").exists():
        print("❌ Error: Please run this script from the 'back' directory")
        sys.exit(1)
    
    # 1. Check if Redis is running
    print("🔍 Checking Redis...")
    if not check_service("Redis", "redis-cli ping"):
        print("❌ Redis is not running. Please start Redis first:")
        print("   brew services start redis  # macOS")
        print("   sudo systemctl start redis  # Linux")
        sys.exit(1)
    print("✅ Redis is running")
    
    # 2. Start Celery Worker
    print("\n🔄 Starting Celery Worker...")
    worker_process = run_command(
        "celery -A celery_app worker --loglevel=info",
        "Celery Worker",
        background=True
    )
    
    if not worker_process:
        print("❌ Failed to start Celery Worker")
        sys.exit(1)
    
    # Wait a bit for worker to start
    time.sleep(3)
    
    # 3. Start Celery Beat (scheduler)
    print("\n🔄 Starting Celery Beat...")
    beat_process = run_command(
        "celery -A celery_app beat --loglevel=info",
        "Celery Beat",
        background=True
    )
    
    if not beat_process:
        print("❌ Failed to start Celery Beat")
        worker_process.terminate()
        sys.exit(1)
    
    # Wait a bit for beat to start
    time.sleep(3)
    
    # 4. Start Flower (monitoring)
    print("\n🔄 Starting Flower (Celery monitoring)...")
    flower_process = run_command(
        "celery -A celery_app flower --port=5555",
        "Flower",
        background=True
    )
    
    # 5. Start FastAPI server
    print("\n🔄 Starting FastAPI server...")
    server_process = run_command(
        "uvicorn main:app --host=0.0.0.0 --port=8000 --reload",
        "FastAPI Server",
        background=True
    )
    
    if not server_process:
        print("❌ Failed to start FastAPI server")
        worker_process.terminate()
        beat_process.terminate()
        if flower_process:
            flower_process.terminate()
        sys.exit(1)
    
    # Wait for server to start
    time.sleep(5)
    
    print("\n" + "=" * 50)
    print("🎉 Chatbot System Started Successfully!")
    print("=" * 50)
    print("📱 Frontend: http://localhost:8000")
    print("📊 Flower (Celery monitoring): http://localhost:5555")
    print("🔧 API Documentation: http://localhost:8000/docs")
    print("\n📋 Services running:")
    print("   ✅ Redis (cache & message broker)")
    print("   ✅ Celery Worker (background tasks)")
    print("   ✅ Celery Beat (scheduled tasks)")
    print("   ✅ Flower (task monitoring)")
    print("   ✅ FastAPI Server (main API)")
    print("\n🔄 Automatic content generation is now running:")
    print("   • Initial content generation: Every 1 minute")
    print("   • Daily content: Every 30 minutes")
    print("   • All topics content: Every hour")
    print("   • Popular topics update: Every 15 minutes")
    print("\n💡 New users will see:")
    print("   • Daily motivational quote")
    print("   • Random psychological articles")
    print("   • Random YouTube videos")
    print("   • Personalized recommendations after chat")
    print("\n⏹️  To stop all services, press Ctrl+C")
    
    try:
        # Keep the script running
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n\n🛑 Stopping all services...")
        
        # Terminate all processes
        if server_process:
            server_process.terminate()
        if flower_process:
            flower_process.terminate()
        if beat_process:
            beat_process.terminate()
        if worker_process:
            worker_process.terminate()
        
        print("✅ All services stopped")
        print("👋 Goodbye!")

if __name__ == "__main__":
    main() 