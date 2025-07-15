import logging
from typing import List, Dict, Optional
from celery_app import celery_app
from ai_service import AIService
from database import Database
import redis
import json
import os
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# Initialize services
try:
    ai_service = AIService()
    db = Database()
    # Move ContentGenerator import inside functions to avoid circular import
except Exception as e:
    logger.error(f"Failed to initialize services: {e}")
    ai_service = None
    db = None

# Redis client for caching
redis_client = redis.Redis.from_url(
    os.getenv("REDIS_URL", "redis://localhost:6379/0"),
    decode_responses=True
)

@celery_app.task
def extract_topic_from_message(message: str, user_id: str = "default", language: str = "ru") -> Dict:
    """
    Extract main topic from user message using AI
    """
    try:
        if not ai_service:
            raise Exception("AI service not available")
        
        # Create prompt for topic extraction based on language
        if language == "en":
            prompt = f"""
            Analyze the user's message and identify ONE main topic.
            
            Message: "{message}"
            
            Requirements:
            - Return only ONE word or short phrase (2-3 words maximum)
            - Topic should be related to psychology, self-help, motivation
            - Example topics: stress, anxiety, motivation, confidence, relationships, career, health
            
            Response format:
            TOPIC: [one word or short phrase]
            """
            system_prompt = "You are an expert at analyzing psychological topics. Identify precise and relevant topics."
        else:
            prompt = f"""
            Проанализируй сообщение пользователя и определи ОДНУ основную тему.
            
            Сообщение: "{message}"
            
            Требования:
            - Верни только ОДНО слово или короткую фразу (2-3 слова максимум)
            - Тема должна быть связана с психологией, самопомощи, мотивацией
            - Примеры тем: стресс, тревога, мотивация, уверенность, отношения, карьера, здоровье
            
            Формат ответа:
            ТЕМА: [одно слово или короткая фраза]
            """
            system_prompt = "Ты эксперт по анализу психологических тем. Определяй точные и релевантные темы."
        
        response = ai_service.client.chat.completions.create(
            model=ai_service.deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt}
            ],
            max_tokens=50,
            temperature=0.3
        )
        
        ai_response = response.choices[0].message.content.strip()
        
        # Extract topic from response
        topic = ai_response
        if language == "en":
            if "TOPIC:" in ai_response:
                topic = ai_response.split("TOPIC:")[1].strip()
        else:
            if "ТЕМА:" in ai_response:
                topic = ai_response.split("ТЕМА:")[1].strip()
        
        # Clean up topic - remove quotes, extra spaces, and limit length
        topic = topic.strip().strip('"').strip("'").strip()
        if len(topic) > 30:  # Increased limit for better readability
            topic = topic[:30].strip()
        
        # Ensure topic is not empty
        if not topic or topic.lower() in ["none", "нет", "неизвестно", "unknown", "тема:", "topic:", "n/a", "н/д"]:
            topic = "общение" if language == "ru" else "communication"
        
        # Additional cleanup - remove any remaining formatting artifacts
        topic = topic.replace("ТЕМА:", "").replace("TOPIC:", "").strip()
        if not topic:
            topic = "общение" if language == "ru" else "communication"
        

        
        # Cache topic for user (short cache time for immediate access)
        cache_key = f"user_topic:{user_id}"
        redis_client.setex(cache_key, 60, topic)  # Cache for 1 minute
        logger.info(f"Cached topic for user {user_id}: '{topic}'")
        
        # Update user's current topic in database
        db.update_user_current_topic(user_id, topic)
        
        # AUTOMATIC CONTENT GENERATION - Generate content for the extracted topic
        logger.info(f"Starting automatic content generation for topic '{topic}'")
        
        # Generate article and quote asynchronously with language
        article_task = generate_content_for_topic.delay(topic, "article", language)
        quote_task = generate_content_for_topic.delay(topic, "quote", language)
        
        # Update user recommendations
        recommendations_task = update_user_recommendations.delay(user_id, language)
        
        logger.info(f"Extracted topic '{topic}' for user {user_id} and started content generation")
        
        return {
            "topic": topic,
            "user_id": user_id,
            "language": language,
            "timestamp": datetime.now().isoformat(),
            "article_task_id": article_task.id,
            "quote_task_id": quote_task.id,
            "recommendations_task_id": recommendations_task.id,
            "auto_generation_started": True
        }
        
    except Exception as e:
        logger.error(f"Error extracting topic: {e}")
        return {"error": str(e)}

@celery_app.task
def generate_content_for_topic(topic: str, content_type: str = "article", language: str = "ru") -> Dict:
    """
    Generate content (article or quote) for specific topic
    """
    try:
        # Import ContentGenerator here to avoid circular import
        from content_generator import ContentGenerator
        
        if not ai_service:
            raise Exception("AI service not available")
        
        content_generator = ContentGenerator(db, ai_service)
        
        if content_type == "article":
            # Generate article for topic
            topic_dict = {"topic": topic, "frequency": 1}
            article = content_generator._generate_article(topic_dict, language)
            
            if article:
                # Cache the article with language
                cache_key = f"article:{topic}:{language}:{datetime.now().strftime('%Y%m%d')}"
                redis_client.setex(cache_key, 86400, json.dumps(article))  # Cache for 24 hours
                
                return {
                    "content_type": "article",
                    "topic": topic,
                    "language": language,
                    "content": article,
                    "cached": True
                }
        
        elif content_type == "quote":
            # Generate quote for topic
            quote = content_generator._generate_quote(topic, language)
            
            if quote:
                # Cache the quote with language
                cache_key = f"quote:{topic}:{language}:{datetime.now().strftime('%Y%m%d')}"
                redis_client.setex(cache_key, 86400, json.dumps(quote))  # Cache for 24 hours
                
                return {
                    "content_type": "quote",
                    "topic": topic,
                    "language": language,
                    "content": quote,
                    "cached": True
                }
        
        return {"error": f"Unknown content type: {content_type}"}
        
    except Exception as e:
        logger.error(f"Error generating content for topic {topic}: {e}")
        return {"error": str(e)}

@celery_app.task
def update_user_recommendations(user_id: str, language: str = "ru") -> Dict:
    """
    Update user's personalized content recommendations
    """
    try:
        # Import ContentGenerator here to avoid circular import
        from content_generator import ContentGenerator
        
        if not ai_service:
            raise Exception("AI service not available")
        
        content_generator = ContentGenerator(db, ai_service)
        
        # Get user's current topic
        current_topic = db.get_user_current_topic(user_id)
        
        if not current_topic:
            return {"message": "No current topic for user"}
        
        # Generate content for current topic with language
        article_task = generate_content_for_topic.delay(current_topic, "article", language)
        quote_task = generate_content_for_topic.delay(current_topic, "quote", language)
        
        # Get videos for topic (YouTube search can include language parameter)
        videos = content_generator.youtube_service.search_videos(current_topic, 5, language)
        
        # Cache recommendations with language
        recommendations = {
            "topic": current_topic,
            "language": language,
            "videos": videos,
            "timestamp": datetime.now().isoformat()
        }
        
        cache_key = f"recommendations:{user_id}:{language}"
        redis_client.setex(cache_key, 1800, json.dumps(recommendations))  # Cache for 30 minutes
        
        return {
            "user_id": user_id,
            "topic": current_topic,
            "language": language,
            "article_task_id": article_task.id,
            "quote_task_id": quote_task.id,
            "videos_count": len(videos),
            "cached": True
        }
        
    except Exception as e:
        logger.error(f"Error updating recommendations for user {user_id}: {e}")
        return {"error": str(e)}

@celery_app.task(bind=True)
def generate_daily_content(self) -> Dict:
    """
    Generate daily content (quotes, articles) based on popular topics
    """
    try:
        # Import ContentGenerator here to avoid circular import
        from content_generator import ContentGenerator
        
        if not ai_service:
            raise Exception("AI service not available")
        
        content_generator = ContentGenerator(db, ai_service)
        
        # Get popular topics from database
        popular_topics = db.get_popular_topics(limit=5)
        
        generated_articles = []
        generated_quotes = []
        
        # Generate content for each popular topic
        for topic_data in popular_topics:
            topic = topic_data["topic"]
            logger.info(f"Generating content for popular topic: {topic}")
            
            # Generate article for topic
            try:
                article = content_generator._generate_article({"topic": topic, "frequency": topic_data.get("frequency", 1)})
                if article:
                    generated_articles.append(article)
                    # Cache the article
                    cache_key = f"article:{topic}:{datetime.now().strftime('%Y%m%d')}"
                    redis_client.setex(cache_key, 86400, json.dumps(article))  # Cache for 24 hours
            except Exception as e:
                logger.error(f"Error generating article for topic {topic}: {e}")
            
            # Generate quote for topic
            try:
                quote = content_generator._generate_quote(topic)
                if quote:
                    generated_quotes.append(quote)
                    # Cache the quote
                    cache_key = f"quote:{topic}:{datetime.now().strftime('%Y%m%d')}"
                    redis_client.setex(cache_key, 86400, json.dumps(quote))  # Cache for 24 hours
            except Exception as e:
                logger.error(f"Error generating quote for topic {topic}: {e}")
        
        # Also generate some general content from chats
        try:
            general_articles = content_generator.generate_content_from_chats("article")
            generated_articles.extend(general_articles)
        except Exception as e:
            logger.error(f"Error generating general articles: {e}")
        
        # Cache daily content
        daily_content = {
            "articles": generated_articles,
            "quotes": generated_quotes,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "topics_processed": [t["topic"] for t in popular_topics]
        }
        
        cache_key = f"daily_content:{datetime.now().strftime('%Y%m%d')}"
        redis_client.setex(cache_key, 86400, json.dumps(daily_content))  # Cache for 24 hours
        
        logger.info(f"Generated daily content: {len(generated_articles)} articles, {len(generated_quotes)} quotes for {len(popular_topics)} topics")
        
        return {
            "articles_generated": len(generated_articles),
            "quotes_generated": len(generated_quotes),
            "topics_processed": len(popular_topics),
            "cached": True
        }
        
    except Exception as e:
        logger.error(f"Error generating daily content: {e}")
        self.retry(countdown=300, max_retries=3)
        return {"error": str(e)}

@celery_app.task(bind=True)
def update_popular_topics(self) -> Dict:
    """
    Update popular topics based on recent conversations
    """
    try:
        if not db:
            raise Exception("Database not available")
        
        # This would typically analyze recent messages and update topic frequencies
        # For now, just log the task
        logger.info("Updating popular topics")
        
        return {"message": "Popular topics updated"}
        
    except Exception as e:
        logger.error(f"Error updating popular topics: {e}")
        return {"error": str(e)}

@celery_app.task(bind=True)
def cleanup_old_content(self) -> Dict:
    """
    Clean up old cached content and database entries
    """
    try:
        # Clean up old Redis keys (older than 7 days)
        old_date = (datetime.now() - timedelta(days=7)).strftime('%Y%m%d')
        
        # This is a simplified cleanup - in production you'd want more sophisticated logic
        logger.info("Cleaning up old content")
        
        return {"message": "Old content cleaned up"}
        
    except Exception as e:
        logger.error(f"Error cleaning up old content: {e}")
        return {"error": str(e)}

@celery_app.task
def generate_content_for_all_topics() -> Dict:
    """
    Generate content for all active topics in the system
    """
    try:
        # Import ContentGenerator here to avoid circular import
        from content_generator import ContentGenerator
        
        if not ai_service:
            raise Exception("AI service not available")
        
        content_generator = ContentGenerator(db, ai_service)
        
        # Get all active topics from database
        all_topics = db.get_all_topics()
        
        generated_content = {
            "articles": [],
            "quotes": [],
            "topics_processed": []
        }
        
        logger.info(f"Starting content generation for {len(all_topics)} topics")
        
        for topic_data in all_topics:
            topic = topic_data["topic"]
            frequency = topic_data.get("frequency", 1)
            
            logger.info(f"Generating content for topic: {topic} (frequency: {frequency})")
            
            # Generate article for topic
            try:
                article = content_generator._generate_article({"topic": topic, "frequency": frequency})
                if article:
                    generated_content["articles"].append(article)
                    # Cache the article
                    cache_key = f"article:{topic}:{datetime.now().strftime('%Y%m%d')}"
                    redis_client.setex(cache_key, 86400, json.dumps(article))  # Cache for 24 hours
            except Exception as e:
                logger.error(f"Error generating article for topic {topic}: {e}")
            
            # Generate quote for topic
            try:
                quote = content_generator._generate_quote(topic)
                if quote:
                    generated_content["quotes"].append(quote)
                    # Cache the quote
                    cache_key = f"quote:{topic}:{datetime.now().strftime('%Y%m%d')}"
                    redis_client.setex(cache_key, 86400, json.dumps(quote))  # Cache for 24 hours
            except Exception as e:
                logger.error(f"Error generating quote for topic {topic}: {e}")
            
            generated_content["topics_processed"].append(topic)
        
        # Cache the generated content
        cache_key = f"all_topics_content:{datetime.now().strftime('%Y%m%d')}"
        redis_client.setex(cache_key, 86400, json.dumps(generated_content))  # Cache for 24 hours
        
        logger.info(f"Generated content for all topics: {len(generated_content['articles'])} articles, {len(generated_content['quotes'])} quotes")
        
        return {
            "articles_generated": len(generated_content["articles"]),
            "quotes_generated": len(generated_content["quotes"]),
            "topics_processed": len(generated_content["topics_processed"]),
            "cached": True
        }
        
    except Exception as e:
        logger.error(f"Error generating content for all topics: {e}")
        return {"error": str(e)}

@celery_app.task
def initialize_startup_content() -> Dict:
    """
    Initialize startup content for new users (quotes, articles, videos)
    """
    try:
        # Import ContentGenerator here to avoid circular import
        from content_generator import ContentGenerator
        
        if not ai_service:
            raise Exception("AI service not available")
        
        content_generator = ContentGenerator(db, ai_service)
        
        # Initialize default quotes if database is empty
        if not db.get_quotes(limit=1):
            db.populate_default_quotes()
            logger.info("Initialized default quotes")
        
        # Generate initial articles for common psychological topics
        common_topics = ["стресс", "тревога", "мотивация", "уверенность", "отношения", "здоровье"]
        
        generated_articles = []
        for topic in common_topics:
            try:
                article = content_generator._generate_article({"topic": topic, "frequency": 1})
                if article:
                    generated_articles.append(article)
                    logger.info(f"Generated initial article for topic: {topic}")
            except Exception as e:
                logger.error(f"Error generating initial article for {topic}: {e}")
        
        # Cache initial content
        initial_content = {
            "articles": generated_articles,
            "topics_processed": common_topics,
            "initialized_at": datetime.now().isoformat()
        }
        
        cache_key = "initial_content"
        redis_client.setex(cache_key, 86400, json.dumps(initial_content))  # Cache for 24 hours
        
        logger.info(f"Initialized startup content: {len(generated_articles)} articles for {len(common_topics)} topics")
        
        return {
            "articles_generated": len(generated_articles),
            "topics_processed": len(common_topics),
            "cached": True
        }
        
    except Exception as e:
        logger.error(f"Error initializing startup content: {e}")
        return {"error": str(e)}

# Utility functions for other parts of the application
def get_cached_topic(user_id: str) -> Optional[str]:
    """Get cached topic for user"""
    cache_key = f"user_topic:{user_id}"
    topic = redis_client.get(cache_key)
    if topic:
        # Ensure proper string encoding
        if isinstance(topic, bytes):
            return topic.decode('utf-8')
        return topic
    
    # Fallback to database if cache is empty
    if db:
        db_topic = db.get_user_current_topic(user_id)
        if db_topic:
            # Cache it for future requests (5 minutes to match extract_topic_from_message)
            redis_client.setex(cache_key, 300, db_topic)
            return db_topic
    
    return None

def get_cached_recommendations(user_id: str) -> Optional[Dict]:
    """Get cached recommendations for user"""
    cache_key = f"recommendations:{user_id}"
    data = redis_client.get(cache_key)
    if data:
        return json.loads(data)
    return None

def get_cached_daily_content() -> Optional[Dict]:
    """Get cached daily content"""
    cache_key = f"daily_content:{datetime.now().strftime('%Y%m%d')}"
    data = redis_client.get(cache_key)
    if data:
        return json.loads(data)
    return None

def force_refresh_topic(user_id: str) -> None:
    """Force refresh topic cache for user (clear cache to force new extraction)"""
    cache_key = f"user_topic:{user_id}"
    
    # Get current topic before clearing
    current_topic = redis_client.get(cache_key)
    if current_topic:
        logger.info(f"Clearing topic cache for user {user_id}, current topic: '{current_topic}'")
    else:
        logger.info(f"Clearing topic cache for user {user_id}, no current topic")
    
    redis_client.delete(cache_key)
    
    # Also clear from database to force fresh extraction
    if db:
        db.update_user_current_topic(user_id, None)
    
    logger.info(f"Force refreshed topic cache for user {user_id}") 