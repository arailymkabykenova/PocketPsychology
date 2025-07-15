#!/usr/bin/env python3
"""
Production-ready startup script for Chatbot System
"""

import os
import sys
import subprocess
import time
import signal
import logging
import psutil
from pathlib import Path
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('chatbot.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class ProcessManager:
    """Manages system processes"""
    
    def __init__(self):
        self.processes = {}
        self.pid_file = "chatbot.pid"
        
    def check_redis(self):
        """Check if Redis is running"""
        try:
            import redis
            r = redis.Redis(host='localhost', port=6379, db=0)
            r.ping()
            logger.info("✅ Redis is running")
            return True
        except Exception as e:
            logger.error(f"❌ Redis is not running: {e}")
            return False
    
    def start_redis(self):
        """Start Redis if not running"""
        if self.check_redis():
            return True
        
        logger.info("🚀 Starting Redis...")
        try:
            subprocess.run(["redis-server", "--daemonize", "yes"], check=True)
            time.sleep(2)
            if self.check_redis():
                logger.info("✅ Redis started successfully")
                return True
            else:
                logger.error("❌ Failed to start Redis")
                return False
        except FileNotFoundError:
            logger.error("❌ Redis not found. Please install Redis first")
            return False
    
    def start_process(self, name, command, env=None):
        """Start a process and track it"""
        try:
            process_env = os.environ.copy()
            if env:
                process_env.update(env)
            
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=process_env
            )
            
            time.sleep(2)
            if process.poll() is None:
                self.processes[name] = process
                logger.info(f"✅ {name} started (PID: {process.pid})")
                return True
            else:
                logger.error(f"❌ Failed to start {name}")
                return False
        except Exception as e:
            logger.error(f"❌ Error starting {name}: {e}")
            return False
    
    def start_celery_worker(self):
        """Start Celery worker with proper configuration"""
        return self.start_process(
            "Celery Worker",
            [sys.executable, "start_celery.py"]
        )
    
    def start_fastapi(self):
        """Start FastAPI server"""
        return self.start_process(
            "FastAPI Server",
            [sys.executable, "main.py"]
        )
    
    def start_monitoring(self):
        """Start monitoring process"""
        return self.start_process(
            "Monitoring",
            [sys.executable, "monitor.py"]
        )
    
    def cleanup(self):
        """Cleanup all processes"""
        logger.info("🛑 Stopping all processes...")
        for name, process in self.processes.items():
            if process and process.poll() is None:
                logger.info(f"Stopping {name} (PID: {process.pid})")
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    logger.warning(f"Force killing {name}")
                    process.kill()
        
        # Remove PID file
        if os.path.exists(self.pid_file):
            os.remove(self.pid_file)
    
    def save_pid(self):
        """Save current process PID"""
        with open(self.pid_file, 'w') as f:
            f.write(str(os.getpid()))
    
    def check_health(self):
        """Check health of all processes"""
        healthy = True
        for name, process in self.processes.items():
            if process and process.poll() is not None:
                logger.warning(f"⚠️ {name} has stopped")
                healthy = False
        return healthy

class DatabaseManager:
    """Manages database operations"""
    
    def __init__(self, db_path="chatbot.db"):
        self.db_path = db_path
    
    def get_size(self):
        """Get database size"""
        if os.path.exists(self.db_path):
            size = os.path.getsize(self.db_path)
            return size
        return 0
    
    def backup(self):
        """Create database backup"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = f"backup/chatbot_{timestamp}.db"
        
        # Create backup directory
        os.makedirs("backup", exist_ok=True)
        
        try:
            import shutil
            shutil.copy2(self.db_path, backup_path)
            logger.info(f"✅ Database backed up to {backup_path}")
            return backup_path
        except Exception as e:
            logger.error(f"❌ Backup failed: {e}")
            return None
    
    def cleanup_old_backups(self, keep_days=7):
        """Clean up old backups"""
        import glob
        from datetime import datetime, timedelta
        
        backup_dir = "backup"
        if not os.path.exists(backup_dir):
            return
        
        cutoff_date = datetime.now() - timedelta(days=keep_days)
        
        for backup_file in glob.glob(f"{backup_dir}/chatbot_*.db"):
            file_time = datetime.fromtimestamp(os.path.getctime(backup_file))
            if file_time < cutoff_date:
                try:
                    os.remove(backup_file)
                    logger.info(f"🗑️ Removed old backup: {backup_file}")
                except Exception as e:
                    logger.error(f"❌ Failed to remove backup {backup_file}: {e}")

class LogManager:
    """Manages log rotation"""
    
    def __init__(self, log_file="chatbot.log", max_size_mb=10):
        self.log_file = log_file
        self.max_size_bytes = max_size_mb * 1024 * 1024
    
    def rotate_if_needed(self):
        """Rotate log file if it's too large"""
        if not os.path.exists(self.log_file):
            return
        
        size = os.path.getsize(self.log_file)
        if size > self.max_size_bytes:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            rotated_file = f"{self.log_file}.{timestamp}"
            
            try:
                import shutil
                shutil.move(self.log_file, rotated_file)
                logger.info(f"📄 Log rotated to {rotated_file}")
            except Exception as e:
                logger.error(f"❌ Log rotation failed: {e}")

def main():
    """Main function"""
    print("🤖 Starting Chatbot System (Production Mode)")
    print("=" * 50)
    
    # Change to script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Initialize managers
    process_manager = ProcessManager()
    db_manager = DatabaseManager()
    log_manager = LogManager()
    
    # Save PID
    process_manager.save_pid()
    
    # Rotate logs if needed
    log_manager.rotate_if_needed()
    
    # Start Redis
    if not process_manager.start_redis():
        sys.exit(1)
    
    # Start services
    services_started = 0
    if process_manager.start_celery_worker():
        services_started += 1
    
    if process_manager.start_fastapi():
        services_started += 1
    
    if process_manager.start_monitoring():
        services_started += 1
    
    if services_started == 0:
        logger.error("❌ No services started successfully")
        sys.exit(1)
    
    print("\n" + "=" * 50)
    print("🎉 Production system started!")
    print(f"📊 Services running: {services_started}")
    print(f"🗄️ Database size: {db_manager.get_size() / 1024:.1f}KB")
    print("\nServices:")
    print("  • FastAPI Server: http://localhost:8000")
    print("  • API Documentation: http://localhost:8000/docs")
    print("  • Health Check: http://localhost:8000/health")
    print("\nPress Ctrl+C to stop all services")
    print("=" * 50)
    
    # Set up signal handler
    def signal_handler(signum, frame):
        logger.info("Received shutdown signal")
        process_manager.cleanup()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Main loop with health checks
    last_backup = time.time()
    backup_interval = 24 * 60 * 60  # 24 hours
    
    try:
        while True:
            time.sleep(30)  # Check every 30 seconds
            
            # Health check
            if not process_manager.check_health():
                logger.warning("⚠️ Some processes are unhealthy")
            
            # Database backup (daily)
            current_time = time.time()
            if current_time - last_backup > backup_interval:
                db_manager.backup()
                db_manager.cleanup_old_backups()
                last_backup = current_time
            
            # Log rotation check
            log_manager.rotate_if_needed()
            
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully...")
        process_manager.cleanup()

if __name__ == "__main__":
    main() 