# AI Chatbot Backend

FastAPI backend for AI chatbot with three conversation modes, enhanced with Redis caching and Celery for asynchronous task processing.

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)
```bash
# Clone and setup
git clone <repository>
cd back

# Copy environment variables
cp env.example .env
# Edit .env with your credentials

# Start all services
docker-compose up -d
```

### Option 2: Manual Setup
```bash
# 1. Install Redis
brew install redis && brew services start redis  # macOS
# OR
sudo apt install redis-server && sudo systemctl start redis-server  # Ubuntu

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment variables
cp env.example .env
# Edit .env file with your credentials

# 5. Start all services
python start_all.py
```

## 🔧 Setup

### Required Environment Variables
```env
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=your_azure_openai_endpoint_here
AZURE_OPENAI_API_KEY=your_azure_openai_api_key_here
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here

# YouTube API Configuration (optional)
YOUTUBE_API_KEY=your_youtube_api_key_here

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Server Configuration
HOST=0.0.0.0
PORT=8000
```

## 🏃‍♂️ Running the System

### All-in-One Script
```bash
python start_all.py
```

### Individual Services
```bash
# 1. Start Redis (if not running as service)
redis-server

# 2. Start Celery Worker (in separate terminal)
python start_celery.py

# 3. Start Celery Beat Scheduler (in separate terminal)
python start_celery_beat.py

# 4. Start FastAPI Server (in separate terminal)
python main.py

# 5. Start Flower Monitoring (optional, in separate terminal)
celery -A celery_app flower --port=5555
```

## 🌐 Services

- **FastAPI Server**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Flower Monitoring**: http://localhost:5555

## 📡 API Endpoints

### Chat Endpoints
- `GET /`: Health check
- `GET /health`: Detailed health check
- `POST /chat`: Main chat endpoint (now returns topic and task IDs)
- `POST /clear-history`: Clear conversation history

### Task Management
- `GET /task/{task_id}/status`: Get Celery task status
- `GET /user/{user_id}/topic`: Get user's current topic
- `GET /user/{user_id}/recommendations`: Get personalized recommendations

### Content Endpoints
- `GET /content/daily-quote`: Get daily motivational quote
- `GET /content/articles`: Get generated articles (with optional topic filter)
- `GET /content/videos`: Get YouTube video recommendations (with optional topic filter)
- `POST /content/generate`: Generate new content (articles or quotes)

## 🤖 Chat Modes

1. **Support**: Empathetic listening without advice
2. **Analysis**: Socratic dialogue for self-reflection
3. **Practice**: CBT techniques and practical advice

## ✨ Enhanced Features

### 🔄 **Asynchronous Processing**
- **Topic Extraction**: AI automatically extracts topics from user messages
- **Content Generation**: Background generation of articles and quotes
- **Recommendations**: Personalized content based on conversation history
- **Task Monitoring**: Real-time task status tracking

### 🚀 **Redis Caching**
- **User Topics**: Cached for 1 hour
- **Recommendations**: Cached for 30 minutes
- **Articles**: Cached for 24 hours
- **Quotes**: Cached for 24 hours
- **Daily Content**: Cached for 24 hours

### 📊 **Celery Tasks**
- `extract_topic_from_message`: Extract topics from user messages
- `generate_content_for_topic`: Generate content for specific topics
- `update_user_recommendations`: Update personalized recommendations
- `generate_daily_content`: Generate daily content (scheduled)
- `update_popular_topics`: Update popular topics (scheduled)
- `cleanup_old_content`: Clean up old cached content (scheduled)

### 🎯 **Automatic Content Adaptation**
After each chat message:
1. AI generates response
2. Celery extracts topic from message
3. Celery updates user recommendations
4. Frontend receives topic and can load relevant content

## 🗄️ Database Schema

The system uses SQLite with the following tables:
- `conversations`: Chat message history
- `topics`: Extracted conversation topics
- `generated_content`: AI-generated articles
- `quotes`: Motivational quotes
- `user_sessions`: User activity tracking
- `user_topics`: User's current and recent topics

## 🧪 Testing

### Test Content System
```bash
python test_quotes.py
```

### Manual API Testing
```bash
# Get daily quote
curl http://localhost:8000/content/daily-quote

# Get articles
curl http://localhost:8000/content/articles?limit=5

# Get videos by topic
curl "http://localhost:8000/content/videos?topic=мотивация&limit=3"

# Send chat message (returns topic and task IDs)
curl -X POST "http://localhost:8000/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Я чувствую стресс на работе", "mode": "support", "user_id": "test_user"}'

# Get user's current topic
curl http://localhost:8000/user/test_user/topic

# Get user's recommendations
curl http://localhost:8000/user/test_user/recommendations

# Check task status
curl http://localhost:8000/task/{task_id}/status
```

## 📚 Documentation

- [Redis & Celery Setup](CELERY_REDIS_SETUP.md) - Detailed setup guide
- [Quotes System](QUOTES_SYSTEM.md) - Quotes system guide
- [YouTube Integration](YOUTUBE_INTEGRATION.md) - YouTube video recommendations
- [Frontend API Guide](FRONTEND_API_GUIDE.md) - Frontend integration guide
- [System Overview](SYSTEM_OVERVIEW.md) - Overall system architecture

## 🐳 Docker Deployment

### Development
```bash
docker-compose up -d
```

### Production
```bash
# Build and run
docker-compose -f docker-compose.yml up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 🔍 Monitoring

### Flower Dashboard
- **URL**: http://localhost:5555
- **Features**: Task monitoring, worker status, task history
- **Real-time**: Live updates of task execution

### Health Checks
```bash
# Overall health
curl http://localhost:8000/health

# Redis connection
redis-cli ping

# Celery worker status
celery -A celery_app inspect active
```

## 🚨 Troubleshooting

### Common Issues
1. **Redis Connection**: Ensure Redis is running on port 6379
2. **Celery Tasks**: Check Flower dashboard for task status
3. **Import Errors**: Ensure PYTHONPATH includes current directory
4. **Permission Issues**: Make scripts executable with `chmod +x`

### Logs
```bash
# FastAPI logs
docker-compose logs web

# Celery worker logs
docker-compose logs worker

# Redis logs
docker-compose logs redis
``` 