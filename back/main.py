import os
import logging
from typing import Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from models import ChatRequest, ChatResponse, ChatMode, TopicExtractionRequest, TopicExtractionResponse, TaskStatusResponse
from ai_service import AIService
from content_generator import ContentGenerator
from tasks import get_cached_topic, get_cached_recommendations, get_cached_daily_content, get_initial_random_content
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
    try:
        # Test Redis connection and write/read
        from tasks import redis_client
        redis_status = "unavailable"
        redis_test = "not tested"
        
        try:
            redis_client.ping()
            redis_status = "available"
            
            # Test Redis write/read
            test_key = "health_test"
            test_value = "test_data"
            redis_client.setex(test_key, 60, test_value)
            retrieved_value = redis_client.get(test_key)
            if retrieved_value == test_value:
                redis_test = "write/read OK"
            else:
                redis_test = f"write/read failed: expected '{test_value}', got '{retrieved_value}'"
            redis_client.delete(test_key)
            
        except Exception as e:
            redis_status = f"error: {str(e)}"
            redis_test = "failed"
        
        return {
            "status": "healthy",
            "ai_service": "available" if ai_service else "unavailable",
            "celery": "available" if celery_app else "unavailable",
            "redis": {
                "status": redis_status,
                "test": redis_test
            },
            "environment": {
                "azure_endpoint": bool(os.getenv("AZURE_OPENAI_ENDPOINT")),
                "azure_api_key": bool(os.getenv("AZURE_OPENAI_API_KEY")),
                "deployment_name": bool(os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME")),
                "redis_url": bool(os.getenv("REDIS_URL"))
            }
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}


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
async def get_daily_quote(language: str = "ru", topic: Optional[str] = None):
    """Get daily motivational quote, optionally personalized for topic"""
    try:
        if content_generator is None:
            raise HTTPException(status_code=500, detail="Content generator not available")
        
        if topic:
            # Try to get cached quote for topic
            from tasks import redis_client
            import json
            from datetime import datetime
            
            cache_key = f"quote:{topic}:{language}:{datetime.now().strftime('%Y%m%d')}"
            logger.info(f"Looking for cached quote with key: '{cache_key}'")
            cached_data = redis_client.get(cache_key)
            
            if cached_data:
                quote = json.loads(cached_data)
                logger.info(f"Found cached quote for topic '{topic}': {quote.get('text', '')[:50]}...")
                return quote
            else:
                logger.info(f"No cached quote found for topic '{topic}', generating new one")
                # Generate new quote for topic
                quote = content_generator._generate_quote(topic, language=language)
                if quote:
                    # Cache the quote
                    try:
                        quote_json = json.dumps(quote)
                        redis_client.setex(cache_key, 86400, quote_json)  # Cache for 24 hours
                        logger.info(f"Successfully cached quote for topic '{topic}' with key '{cache_key}': {quote.get('text', '')[:50]}...")
                    except Exception as cache_error:
                        logger.error(f"Failed to cache quote for topic '{topic}': {cache_error}")
                        logger.error(f"Redis error details: {cache_error}")
                    return quote
                else:
                    logger.error(f"Failed to generate quote for topic '{topic}'")
                    # Fallback to general daily quote
                    logger.info(f"Falling back to general daily quote for language '{language}'")
                    quote = content_generator.get_daily_quote(language=language)
                    return quote
        
        # Fallback to general daily quote
        logger.info(f"Falling back to general daily quote for language '{language}'")
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
        
        logger.info(f"Getting articles - topic: '{topic}', language: '{language}', limit: {limit}")
        
        if topic:
            # Get cached articles for topic
            from tasks import redis_client
            import json
            from datetime import datetime
            
            cache_key = f"article:{topic}:{language}:{datetime.now().strftime('%Y%m%d')}"
            cached_data = redis_client.get(cache_key)
            
            if cached_data:
                article = json.loads(cached_data)
                logger.info(f"Found cached article for topic '{topic}'")
                return {"articles": [article]}
            else:
                logger.info(f"No cached article found for topic '{topic}', generating new one")
                # Generate new article for topic
                topic_dict = {"topic": topic, "frequency": 1}
                article = content_generator._generate_article(topic_dict, language=language)
                if article:
                    # Cache the article
                    try:
                        article_json = json.dumps(article)
                        logger.info(f"Attempting to cache article JSON: {article_json[:100]}...")
                        redis_client.setex(cache_key, 86400, article_json)  # Cache for 24 hours
                        logger.info(f"Successfully cached article for topic '{topic}' with key '{cache_key}'")
                        
                        # Verify cache
                        verify_data = redis_client.get(cache_key)
                        if verify_data:
                            logger.info(f"Cache verification successful for key '{cache_key}'")
                        else:
                            logger.error(f"Cache verification failed for key '{cache_key}' - got None")
                        
                        # Also save to database for fallback
                        try:
                            ai_service.db.save_generated_content(
                                content_type="article",
                                title=article["title"],
                                content=article["content"],
                                source_topics=[topic]
                            )
                            logger.info(f"Saved article for topic '{topic}' to database")
                        except Exception as db_error:
                            logger.error(f"Failed to save article to database: {db_error}")
                            
                    except Exception as cache_error:
                        logger.error(f"Failed to cache article for topic '{topic}': {cache_error}")
                        logger.error(f"Cache error details: {cache_error}")
                        import traceback
                        logger.error(f"Cache error traceback: {traceback.format_exc()}")
                    return {"articles": [article]}
                else:
                    logger.error(f"Failed to generate article for topic '{topic}'")
                    # Fallback to database articles for this topic
                    articles = ai_service.db.get_generated_content("article", limit)
                    logger.info(f"Returning {len(articles)} articles from database as fallback")
                    return {"articles": articles}
        
        # Fallback to database articles
        articles = ai_service.db.get_generated_content("article", limit)
        logger.info(f"Returning {len(articles)} articles from database")
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


@app.get("/test-cache")
async def test_cache():
    """Test Redis caching functionality"""
    try:
        from tasks import redis_client
        import json
        from datetime import datetime
        
        # Test data
        test_data = {
            "text": "Test quote",
            "author": "Test Author",
            "topic": "test",
            "date": datetime.now().strftime("%Y-%m-%d"),
            "is_generated": True
        }
        
        # Test key
        test_key = f"test:quote:test:ru:{datetime.now().strftime('%Y%m%d')}"
        
        # Try to save
        try:
            test_json = json.dumps(test_data)
            redis_client.setex(test_key, 60, test_json)
            logger.info(f"Test: Successfully saved to Redis with key '{test_key}'")
            
            # Try to retrieve
            retrieved_data = redis_client.get(test_key)
            if retrieved_data:
                retrieved_json = json.loads(retrieved_data)
                logger.info(f"Test: Successfully retrieved from Redis: {retrieved_json}")
                success = retrieved_json == test_data
            else:
                logger.error(f"Test: Failed to retrieve from Redis - got None")
                success = False
                
            # Clean up
            redis_client.delete(test_key)
            
            return {
                "success": success,
                "test_key": test_key,
                "saved_data": test_data,
                "retrieved_data": retrieved_json if retrieved_data else None,
                "redis_working": True
            }
            
        except Exception as e:
            logger.error(f"Test: Redis operation failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "redis_working": False
            }
            
    except Exception as e:
        logger.error(f"Test cache error: {e}")
        return {"success": False, "error": str(e)}

@app.get("/content/initial")
async def get_initial_content(language: str = "ru"):
    """Get initial random content for new users"""
    try:
        # Get initial random content from cache
        initial_content = get_initial_random_content()
        
        if not initial_content:
            # If no initial content exists, return empty content
            return {
                "daily_quote": None,
                "random_articles": [],
                "random_videos": [],
                "language": language,
                "is_initial": True
            }
        
        # Get daily quote
        daily_quote = None
        if content_generator:
            daily_quote = content_generator.get_daily_quote(language)
        
        # Get random videos (placeholder for now)
        random_videos = []
        
        return {
            "daily_quote": daily_quote,
            "random_articles": initial_content.get("articles", []),
            "random_videos": random_videos,
            "language": language,
            "is_initial": True
        }
        
    except Exception as e:
        logger.error(f"Error getting initial content: {e}")
        raise HTTPException(status_code=500, detail="Failed to get initial content")





if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", 8000)),
        reload=True
    ) 