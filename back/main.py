import os
import logging
from typing import Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from models import ChatRequest, ChatResponse, ChatMode, TopicExtractionRequest, TopicExtractionResponse, TaskStatusResponse
from ai_service import AIService
from content_generator import ContentGenerator
from tasks import get_cached_topic, get_cached_recommendations, get_cached_daily_content
from celery_app import celery_app

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="AI Chatbot API",
    description="API for AI chatbot with three conversation modes",
    version="1.0.0"
)

# Add CORS middleware for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize AI service
try:
    print("=== Trying to initialize AI service ===")
    ai_service = AIService()
    print("=== AI service initialized successfully ===")
    logger.info("AI service initialized successfully")
    
    # Initialize content generator
    content_generator = ContentGenerator(ai_service.db, ai_service)
    logger.info("Content generator initialized successfully")
    
except Exception as e:
    print(f"=== ERROR initializing AI service: {type(e).__name__}: {str(e)} ===")
    logger.error(f"Failed to initialize AI service: {str(e)}")
    ai_service = None
    content_generator = None


@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "AI Chatbot API is running", "status": "healthy"}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Main chat endpoint that processes user messages and returns AI responses
    Now also extracts topics and triggers content updates
    
    Args:
        request: ChatRequest containing message, mode, user_id, and language
        
    Returns:
        ChatResponse with AI response, mode, topic, and task IDs
    """
    try:
        if ai_service is None:
            raise HTTPException(status_code=500, detail="AI service not available")
        
        # Validate input
        if not request.message.strip():
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        # Get language from request, default to Russian
        language = getattr(request, 'language', 'ru')
        
        logger.info(f"Processing chat request - Mode: {request.mode}, User: {request.user_id}, Language: {language}, Message: {request.message[:50]}...")
        
        # Get AI response with topic extraction
        ai_response_data = await ai_service.get_response(request.message, request.mode, request.user_id, language)
        
        logger.info(f"AI response generated successfully for mode: {request.mode}")
        
        return ChatResponse(
            response=ai_response_data["response"],
            mode=request.mode,
            topic=ai_response_data.get("topic"),
            topic_task_id=ai_response_data.get("topic_task_id"),
            recommendations_task_id=ai_response_data.get("recommendations_task_id")
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/health")
async def health_check():
    """Detailed health check endpoint"""
    return {
        "status": "healthy",
        "ai_service": "available" if ai_service else "unavailable",
        "celery": "available" if celery_app else "unavailable",
        "environment": {
            "azure_endpoint": bool(os.getenv("AZURE_OPENAI_ENDPOINT")),
            "azure_api_key": bool(os.getenv("AZURE_OPENAI_API_KEY")),
            "deployment_name": bool(os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME")),
            "redis_url": bool(os.getenv("REDIS_URL"))
        }
    }


@app.post("/clear-history")
async def clear_history(mode: Optional[ChatMode] = None):
    """Clear conversation history for specific mode or all modes"""
    try:
        if ai_service is None:
            raise HTTPException(status_code=500, detail="AI service not available")
        
        ai_service.clear_conversation_history(mode)
        
        mode_text = mode.value if mode else "all modes"
        logger.info(f"Cleared conversation history for: {mode_text}")
        
        return {"message": f"Conversation history cleared for {mode_text}"}
        
    except Exception as e:
        logger.error(f"Error clearing history: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/task/{task_id}/status", response_model=TaskStatusResponse)
async def get_task_status(task_id: str):
    """Get status of a Celery task"""
    try:
        task = celery_app.AsyncResult(task_id)
        
        if task.ready():
            if task.successful():
                return TaskStatusResponse(
                    task_id=task_id,
                    status="completed",
                    result=task.result
                )
            else:
                return TaskStatusResponse(
                    task_id=task_id,
                    status="failed",
                    error=str(task.info)
                )
        else:
            return TaskStatusResponse(
                task_id=task_id,
                status="pending"
            )
            
    except Exception as e:
        logger.error(f"Error getting task status: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/user/{user_id}/topic")
async def get_user_topic(user_id: str):
    """Get current topic for a user"""
    try:
        topic = get_cached_topic(user_id)
        return {"user_id": user_id, "topic": topic}
        
    except Exception as e:
        logger.error(f"Error getting user topic: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/user/{user_id}/topic/refresh")
async def refresh_user_topic(user_id: str):
    """Force refresh topic for a user (clear cache to force new extraction)"""
    try:
        from tasks import force_refresh_topic
        force_refresh_topic(user_id)
        return {"user_id": user_id, "message": "Topic cache cleared, next message will trigger new topic extraction"}
        
    except Exception as e:
        logger.error(f"Error refreshing user topic: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/user/{user_id}/recommendations")
async def get_user_recommendations(user_id: str):
    """Get personalized recommendations for a user"""
    try:
        recommendations = get_cached_recommendations(user_id)
        if recommendations:
            return recommendations
        else:
            return {"message": "No recommendations available", "user_id": user_id}
            
    except Exception as e:
        logger.error(f"Error getting user recommendations: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/content/daily-quote")
async def get_daily_quote(language: str = "ru"):
    """Get daily motivational quote"""
    try:
        if content_generator is None:
            raise HTTPException(status_code=500, detail="Content generator not available")
        
        quote = content_generator.get_daily_quote(language=language)
        return quote
        
    except Exception as e:
        logger.error(f"Error getting daily quote: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/content/articles")
async def get_articles(limit: int = 10, topic: Optional[str] = None, language: str = "ru"):
    """Get generated articles, optionally filtered by topic"""
    try:
        if content_generator is None:
            raise HTTPException(status_code=500, detail="Content generator not available")
        
        if topic:
            # Get cached articles for topic
            from tasks import redis_client
            import json
            from datetime import datetime
            
            cache_key = f"article:{topic}:{language}:{datetime.now().strftime('%Y%m%d')}"
            cached_data = redis_client.get(cache_key)
            
            if cached_data:
                article = json.loads(cached_data)
                return {"articles": [article]}
        
        # Fallback to database articles
        articles = ai_service.db.get_generated_content("article", limit)
        return {"articles": articles}
        
    except Exception as e:
        logger.error(f"Error getting articles: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/content/videos")
async def get_videos(limit: int = 10, topic: Optional[str] = None, language: str = "ru"):
    """Get YouTube video recommendations"""
    try:
        if content_generator is None:
            raise HTTPException(status_code=500, detail="Content generator not available")
        
        # If topic is provided, search for videos on that topic
        if topic:
            videos = content_generator.youtube_service.search_videos(topic, limit, language=language)
        else:
            # Get popular topics and recommend videos
            popular_topics = ai_service.db.get_popular_topics(limit=3)
            topics = [t["topic"] for t in popular_topics]
            videos = content_generator.get_youtube_recommendations(topics, limit, language=language)
        
        # Format duration for each video
        for video in videos:
            video["formatted_duration"] = content_generator.youtube_service.format_duration(video.get("duration", "PT0S"))
        
        return {"videos": videos}
        
    except Exception as e:
        logger.error(f"Error getting videos: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post("/content/generate")
async def generate_content(content_type: str = "article", topic: Optional[str] = None, language: str = "ru"):
    """Generate content (article or quote) for a specific topic or general content"""
    try:
        if content_generator is None:
            raise HTTPException(status_code=500, detail="Content generator not available")
        
        if topic:
            # Generate content for specific topic
            if content_type == "article":
                topic_dict = {"topic": topic, "frequency": 1}
                content = content_generator._generate_article(topic_dict, language=language)
            elif content_type == "quote":
                content = content_generator._generate_quote(topic, language=language)
            else:
                raise HTTPException(status_code=400, detail="Invalid content type")
            
            if content:
                return {
                    "message": f"Generated {content_type} for topic '{topic}'",
                    "content": content
                }
            else:
                raise HTTPException(status_code=500, detail=f"Failed to generate {content_type}")
        else:
            # Generate general content
            content = content_generator.generate_content_from_chats(content_type, language=language)
            
            return {
                "message": f"Generated {len(content)} {content_type}s",
                "content": content
            }
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating content: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/content/initial")
async def get_initial_content(language: str = "ru"):
    """Get initial content for new users: daily quote + random videos and articles"""
    try:
        if content_generator is None:
            raise HTTPException(status_code=500, detail="Content generator not available")
        
        # Get daily quote
        daily_quote = content_generator.db.get_daily_quote(language=language)
        
        # Try to get cached initial content first
        import redis
        import json
        
        redis_client = redis.Redis.from_url(
            os.getenv("REDIS_URL", "redis://localhost:6379/0"),
            decode_responses=True
        )
        
        cached_content = redis_client.get(f"initial_content:{language}")
        if cached_content:
            initial_content = json.loads(cached_content)
            random_articles = initial_content.get("articles", [])
        else:
            # Fallback to database articles
            random_articles = content_generator.db.get_generated_content("article", limit=3)
        
        # Get random videos on psychological topics based on language
        if language == "en":
            psychological_topics = ["psychology", "motivation", "stress", "anxiety", "confidence", "relationships"]
            welcome_message = "Welcome! Start a conversation and we'll pick personalized recommendations for you."
        else:
            psychological_topics = ["психология", "мотивация", "стресс", "тревога", "уверенность", "отношения"]
            welcome_message = "Добро пожаловать! Начните беседу, и мы подберем для вас персонализированные рекомендации."
        
        import random
        random_topic = random.choice(psychological_topics)
        random_videos = content_generator.youtube_service.search_videos(random_topic, 3, language=language)
        
        return {
            "daily_quote": daily_quote,
            "random_articles": random_articles[:3],  # Limit to 3 articles
            "random_videos": random_videos,
            "welcome_message": welcome_message
        }
        
    except Exception as e:
        logger.error(f"Error getting initial content: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")





if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", 8000)),
        reload=True
    ) 