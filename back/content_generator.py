import logging
from typing import List, Dict, Optional
from datetime import datetime, timedelta
from database import Database
from ai_service import AIService
from youtube_service import YouTubeService

logger = logging.getLogger(__name__)

class ContentGenerator:
    def __init__(self, database: Database, ai_service: AIService):
        self.db = database
        self.ai_service = ai_service
        self.youtube_service = YouTubeService()
    
    def generate_content_from_chats(self, content_type: str = "article") -> List[Dict]:
        """Generate content based on popular topics from conversations"""
        try:
            # Get popular topics
            popular_topics = self.db.get_popular_topics(limit=5)
            
            if not popular_topics:
                logger.info("No popular topics found for content generation")
                return []
            
            generated_content = []
            
            for topic in popular_topics:
                if content_type == "article":
                    # Generate 3 articles for each topic with different approaches
                    articles = self._generate_multiple_articles(topic)
                    generated_content.extend(articles)
                elif content_type == "video":
                    # For videos, we now recommend YouTube videos instead of generating scripts
                    continue  # Videos are handled separately via YouTube API
                else:
                    continue
            
            logger.info(f"Generated {len(generated_content)} {content_type}s")
            return generated_content
            
        except Exception as e:
            logger.error(f"Error generating content: {str(e)}")
            return []
    
    def _generate_multiple_articles(self, topic: Dict, language: str = "ru") -> List[Dict]:
        """Generate 3 articles for a topic with different approaches"""
        articles = []
        
        # Define different article approaches
        approaches = [
            {
                "name": "practical",
                "prompt_suffix": "практические советы и упражнения",
                "system_suffix": "Создавай практичные статьи с конкретными упражнениями и техниками."
            },
            {
                "name": "theoretical", 
                "prompt_suffix": "теоретические основы и понимание",
                "system_suffix": "Создавай образовательные статьи с объяснением психологических концепций."
            },
            {
                "name": "motivational",
                "prompt_suffix": "мотивация и вдохновение",
                "system_suffix": "Создавай вдохновляющие статьи с мотивационными советами."
            }
        ]
        
        for approach in approaches:
            article = None
            max_attempts = 3  # Максимум 3 попытки для каждого подхода
            
            for attempt in range(max_attempts):
                try:
                    article = self._generate_article_with_approach(topic, approach, language)
                    if article:
                        articles.append(article)
                        logger.info(f"Successfully generated {approach['name']} article for topic {topic['topic']} on attempt {attempt + 1}")
                        break
                    else:
                        logger.warning(f"Attempt {attempt + 1} failed for {approach['name']} article on topic {topic['topic']} - got empty result")
                except Exception as e:
                    logger.error(f"Attempt {attempt + 1} failed for {approach['name']} article on topic {topic['topic']}: {str(e)}")
                    if attempt == max_attempts - 1:  # Last attempt
                        logger.error(f"Failed to generate {approach['name']} article for topic {topic['topic']} after {max_attempts} attempts")
            
            # Если не удалось сгенерировать статью, создаем fallback
            if not article:
                logger.warning(f"Creating fallback {approach['name']} article for topic {topic['topic']}")
                fallback_article = self._create_fallback_article(topic, approach, language)
                if fallback_article:
                    articles.append(fallback_article)
                    logger.info(f"Added fallback {approach['name']} article for topic {topic['topic']}")
        
        logger.info(f"Generated {len(articles)} articles for topic {topic['topic']} (target: 3)")
        return articles
    
    def _generate_article_with_approach(self, topic: Dict, approach: Dict, language: str = "ru") -> Optional[Dict]:
        """Generate an article with specific approach"""
        try:
            topic_name = topic["topic"]
            frequency = topic["frequency"]
            approach_name = approach["name"]
            prompt_suffix = approach["prompt_suffix"]
            system_suffix = approach["system_suffix"]
            
            # Create prompt for article generation based on language
            if language == "en":
                prompt = f"""
                Create an article on the topic "{topic_name}" for a self-help application.
                
                Requirements:
                - Title should be attractive and motivating
                - Content should be practical and useful
                - Length: 300-500 words
                - Tone: friendly, supportive
                - Focus on: {prompt_suffix}
                
                Response format:
                TITLE: [article title]
                CONTENT: [article content]
                """
                system_prompt = f"You are an expert in psychology and self-help. {system_suffix}"
            else:
                prompt = f"""
                Создай статью на тему "{topic_name}" для приложения самопомощи.
                
                Требования:
                - Заголовок должен быть привлекательным и мотивирующим
                - Содержание должно быть практичным и полезным
                - Длина: 300-500 слов
                - Тон: дружелюбный, поддерживающий
                - Фокус на: {prompt_suffix}
                
                Формат ответа:
                ЗАГОЛОВОК: [заголовок статьи]
                СОДЕРЖАНИЕ: [содержание статьи]
                """
                system_prompt = f"Ты эксперт по психологии и самопомощи. {system_suffix}"
            
            # Get AI response
            response = self.ai_service.client.chat.completions.create(
                model=self.ai_service.deployment_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=800,
                temperature=0.7
            )
            
            ai_response = response.choices[0].message.content
            
            # Parse response
            lines = ai_response.split('\n')
            title = ""
            content = ""
            content_started = False
            
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                    
                if language == "en":
                    if line.startswith("TITLE:"):
                        title = line.replace("TITLE:", "").strip()
                        content_started = False
                    elif line.startswith("CONTENT:"):
                        content = line.replace("CONTENT:", "").strip()
                        content_started = True
                    elif content_started:
                        content += " " + line
                else:
                    if line.startswith("ЗАГОЛОВОК:"):
                        title = line.replace("ЗАГОЛОВОК:", "").strip()
                        content_started = False
                    elif line.startswith("СОДЕРЖАНИЕ:"):
                        content = line.replace("СОДЕРЖАНИЕ:", "").strip()
                        content_started = True
                    elif content_started:
                        content += " " + line
            
            if title and content:
                return {
                    "title": title,
                    "content": content,
                    "topic": topic_name,
                    "frequency": frequency,
                    "approach": approach_name
                }
            
            return None
            
        except Exception as e:
            logger.error(f"Error generating {approach['name']} article for topic {topic}: {str(e)}")
            return None
    
    def _generate_article(self, topic: Dict, language: str = "ru") -> Optional[Dict]:
        """Generate an article based on a topic (legacy method for compatibility)"""
        try:
            # Use the first approach (practical) for backward compatibility
            approach = {
                "name": "practical",
                "prompt_suffix": "практические советы и упражнения",
                "system_suffix": "Создавай практичные статьи с конкретными упражнениями и техниками."
            }
            return self._generate_article_with_approach(topic, approach, language)
        except Exception as e:
            logger.error(f"Error generating article for topic {topic}: {str(e)}")
            return None
    
    def _create_fallback_article(self, topic: Dict, approach: Dict, language: str = "ru") -> Optional[Dict]:
        """Create a fallback article when AI generation fails"""
        try:
            topic_name = topic["topic"]
            approach_name = approach["name"]
            
            # Fallback content templates based on approach and language
            if language == "en":
                fallback_templates = {
                    "practical": {
                        "title": f"Practical Guide to {topic_name}: Simple Steps for Improvement",
                        "content": f"Dealing with {topic_name} can be challenging, but there are practical steps you can take to improve your situation. Start by identifying the specific aspects of {topic_name} that affect you most. Then, create a simple action plan with small, manageable steps. Remember that progress takes time, and every small improvement counts. Focus on what you can control and celebrate your achievements, no matter how small they may seem."
                    },
                    "theoretical": {
                        "title": f"Understanding {topic_name}: A Comprehensive Overview",
                        "content": f"{topic_name} is a complex psychological concept that affects many aspects of our lives. Understanding the underlying mechanisms and theories can help you better navigate challenges related to {topic_name}. This knowledge provides a foundation for developing effective coping strategies and making informed decisions about your well-being."
                    },
                    "motivational": {
                        "title": f"Finding Strength in {topic_name}: Your Journey to Growth",
                        "content": f"Every challenge related to {topic_name} is an opportunity for personal growth and development. You have the inner strength to overcome difficulties and emerge stronger. Remember that you are not alone in facing these challenges, and your experiences can inspire others. Stay committed to your journey of self-improvement and believe in your ability to create positive change."
                    }
                }
            else:
                fallback_templates = {
                    "practical": {
                        "title": f"Практическое руководство по {topic_name}: Простые шаги к улучшению",
                        "content": f"Работа с {topic_name} может быть сложной, но есть практические шаги, которые вы можете предпринять для улучшения ситуации. Начните с определения конкретных аспектов {topic_name}, которые больше всего влияют на вас. Затем создайте простой план действий с небольшими, выполнимыми шагами. Помните, что прогресс требует времени, и каждое небольшое улучшение имеет значение."
                    },
                    "theoretical": {
                        "title": f"Понимание {topic_name}: Комплексный обзор",
                        "content": f"{topic_name} - это сложная психологическая концепция, которая влияет на многие аспекты нашей жизни. Понимание основных механизмов и теорий может помочь вам лучше справляться с проблемами, связанными с {topic_name}. Эти знания служат основой для разработки эффективных стратегий преодоления трудностей."
                    },
                    "motivational": {
                        "title": f"Найти силу в {topic_name}: Ваш путь к росту",
                        "content": f"Каждый вызов, связанный с {topic_name}, - это возможность для личностного роста и развития. У вас есть внутренняя сила, чтобы преодолевать трудности и становиться сильнее. Помните, что вы не одиноки в решении этих проблем, и ваш опыт может вдохновить других."
                    }
                }
            
            template = fallback_templates.get(approach_name, fallback_templates["practical"])
            
            return {
                "title": template["title"],
                "content": template["content"],
                "topic": topic_name,
                "frequency": topic.get("frequency", 1),
                "approach": approach_name,
                "is_fallback": True
            }
            
        except Exception as e:
            logger.error(f"Error creating fallback article for topic {topic['topic']}: {str(e)}")
            return None
    
    def _generate_video_script(self, topic: Dict) -> Optional[Dict]:
        """Generate a video script based on a topic"""
        try:
            topic_name = topic["topic"]
            frequency = topic["frequency"]
            
            # Create prompt for video script generation
            prompt = f"""
            Создай сценарий для мотивационного видео на тему "{topic_name}".
            
            Требования:
            - Заголовок должен быть привлекательным
            - Сценарий должен быть на 3-5 минут видео
            - Включи вступление, основную часть и заключение
            - Тон: мотивирующий, вдохновляющий
            - Добавь практические советы
            
            Формат ответа:
            ЗАГОЛОВОК: [заголовок видео]
            СЦЕНАРИЙ: [сценарий видео]
            """
            
            # Get AI response
            response = self.ai_service.client.chat.completions.create(
                model=self.ai_service.deployment_name,
                messages=[
                    {"role": "system", "content": "Ты эксперт по созданию мотивационных видео. Создавай вдохновляющие сценарии."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=1000,
                temperature=0.8
            )
            
            ai_response = response.choices[0].message.content
            
            # Parse response
            lines = ai_response.split('\n')
            title = ""
            content = ""
            content_started = False
            
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                    
                if line.startswith("ЗАГОЛОВОК:"):
                    title = line.replace("ЗАГОЛОВОК:", "").strip()
                    content_started = False
                elif line.startswith("СЦЕНАРИЙ:"):
                    content = line.replace("СЦЕНАРИЙ:", "").strip()
                    content_started = True
                elif content_started:
                    content += " " + line
            
            if title and content:
                return {
                    "title": title,
                    "content": content,
                    "topic": topic_name,
                    "frequency": frequency
                }
            
            return None
            
        except Exception as e:
            logger.error(f"Error generating video script for topic {topic}: {str(e)}")
            return None
    
    def get_daily_quote(self, language: str = "ru") -> Dict:
        """Generate or retrieve a daily quote"""
        try:
            logger.info(f"Getting daily quote for language: {language}")
            
            # Populate default quotes if database is empty
            self.db.populate_default_quotes()
            
            # Try to generate a new quote first (30% chance to reduce AI calls)
            import random
            if random.random() < 0.3:
                try:
                    logger.info(f"Attempting to generate new quote for language: {language}")
                    generated_quote = self._generate_quote(language=language)
                    if generated_quote and generated_quote.get("text"):
                        logger.info(f"Successfully generated quote for language: {language}")
                        return generated_quote
                except Exception as e:
                    logger.warning(f"Failed to generate quote, falling back to database: {e}")
            
            # Fallback to database quote
            logger.info(f"Getting quote from database for language: {language}")
            quote = self.db.get_daily_quote(language)
            
            if quote:
                logger.info(f"Found quote in database for language: {language}")
                return quote
            else:
                logger.warning(f"No quote found in database for language: {language}, using fallback")
                # Final fallback to hardcoded quote based on language
                if language == "en":
                    return {
                        "text": "Be the change you wish to see in the world",
                        "author": "Mahatma Gandhi",
                        "topic": "motivation",
                        "date": datetime.now().strftime("%Y-%m-%d")
                    }
                else:
                    return {
                        "text": "Будь изменением, которое ты хочешь видеть в мире",
                        "author": "Махатма Ганди",
                        "topic": "мотивация",
                        "date": datetime.now().strftime("%Y-%m-%d")
                    }
                
        except Exception as e:
            logger.error(f"Error getting daily quote: {str(e)}")
            if language == "en":
                return {
                    "text": "Be the change you wish to see in the world",
                    "author": "Mahatma Gandhi",
                    "topic": "motivation",
                    "date": datetime.now().strftime("%Y-%m-%d")
                }
            else:
                return {
                    "text": "Будь изменением, которое ты хочешь видеть в мире",
                    "author": "Махатма Ганди",
                    "topic": "мотивация",
                    "date": datetime.now().strftime("%Y-%m-%d")
                }
    
    def _generate_quote(self, topic: str = None, language: str = "ru") -> Dict:
        """Generate a quote using AI"""
        try:
            if not topic:
                # Get popular topics and select one
                popular_topics = self.db.get_popular_topics(limit=5)
                if popular_topics:
                    topic = popular_topics[0]["topic"]
                else:
                    topic = "мотивация" if language == "ru" else "motivation"
            
            # Create prompt for quote generation based on language
            if language == "en":
                prompt = f"""
                Create a motivational quote on the topic "{topic}".
                
                Requirements:
                - Quote should be short and memorable (1-2 sentences)
                - Should be inspiring and motivating
                - Come up with a suitable author (famous or unknown)
                - Tone: positive, supportive
                
                Response format:
                QUOTE: [quote text]
                AUTHOR: [author name]
                """
                system_prompt = "You are an expert at creating motivational quotes. Create inspiring and memorable phrases."
                fallback_text = "Every day is a new opportunity to become better"
                fallback_author = "Unknown"
                fallback_topic = "motivation"
            else:
                prompt = f"""
                Создай мотивационную цитату на тему "{topic}".
                
                Требования:
                - Цитата должна быть короткой и запоминающейся (1-2 предложения)
                - Должна быть вдохновляющей и мотивирующей
                - Придумай подходящего автора (известного или неизвестного)
                - Тон: позитивный, поддерживающий
                
                Формат ответа:
                ЦИТАТА: [текст цитаты]
                АВТОР: [имя автора]
                """
                system_prompt = "Ты эксперт по созданию мотивационных цитат. Создавай вдохновляющие и запоминающиеся фразы."
                fallback_text = "Каждый день - это новая возможность стать лучше"
                fallback_author = "Неизвестный"
                fallback_topic = "мотивация"
            
            # Get AI response
            response = self.ai_service.client.chat.completions.create(
                model=self.ai_service.deployment_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=200,
                temperature=0.8
            )
            
            ai_response = response.choices[0].message.content
            
            # Parse response
            lines = ai_response.split('\n')
            quote_text = ""
            author = fallback_author
            
            for line in lines:
                if language == "en":
                    if line.startswith("QUOTE:"):
                        quote_text = line.replace("QUOTE:", "").strip()
                    elif line.startswith("AUTHOR:"):
                        author = line.replace("AUTHOR:", "").strip()
                else:
                    if line.startswith("ЦИТАТА:"):
                        quote_text = line.replace("ЦИТАТА:", "").strip()
                    elif line.startswith("АВТОР:"):
                        author = line.replace("АВТОР:", "").strip()
            
            if quote_text:
                # Save to database
                self.db.save_quote(quote_text, author, topic, language, True)
                
                return {
                    "text": quote_text,
                    "author": author,
                    "topic": topic,
                    "date": datetime.now().strftime("%Y-%m-%d"),
                    "is_generated": True
                }
            
            # Fallback
            return {
                "text": fallback_text,
                "author": fallback_author,
                "topic": fallback_topic,
                "date": datetime.now().strftime("%Y-%m-%d")
            }
            
        except Exception as e:
            logger.error(f"Error generating quote: {str(e)}")
            if language == "en":
                return {
                    "text": "Be the change you wish to see in the world",
                    "author": "Mahatma Gandhi",
                    "topic": "motivation",
                    "date": datetime.now().strftime("%Y-%m-%d")
                }
            else:
                return {
                    "text": "Будь изменением, которое ты хочешь видеть в мире",
                    "author": "Махатма Ганди",
                    "topic": "мотивация",
                    "date": datetime.now().strftime("%Y-%m-%d")
                }
    
    def get_quotes_by_topic(self, topic: str, language: str = "ru", limit: int = 5) -> List[Dict]:
        """Get quotes for a specific topic"""
        try:
            quotes = self.db.get_quotes_by_topic(topic, language, limit)
            
            # If not enough quotes, generate some
            if len(quotes) < limit:
                needed = limit - len(quotes)
                for _ in range(needed):
                    generated_quote = self._generate_quote(topic)
                    if generated_quote:
                        quotes.append(generated_quote)
            
            return quotes
            
        except Exception as e:
            logger.error(f"Error getting quotes by topic: {str(e)}")
            return []
    
    def get_personalized_content(self, user_id: str) -> Dict:
        """Get personalized content based on user's conversation history"""
        try:
            # Get user stats
            user_stats = self.db.get_user_stats(user_id)
            
            # Get user's most used mode
            messages_by_mode = user_stats.get("messages_by_mode", {})
            if messages_by_mode:
                most_used_mode = max(messages_by_mode, key=messages_by_mode.get)
            else:
                most_used_mode = "support"
            
            # Get popular topics for that mode
            popular_topics = self.db.get_popular_topics(mode=most_used_mode, limit=3)
            
            # Get existing content
            articles = self.db.get_generated_content("article", limit=3)
            
            # Get YouTube video recommendations based on popular topics
            topic_names = [topic["topic"] for topic in popular_topics]
            youtube_videos = self.youtube_service.get_recommended_videos(topic_names, max_results=3)
            
            return {
                "user_stats": user_stats,
                "most_used_mode": most_used_mode,
                "popular_topics": popular_topics,
                "recommended_articles": articles,
                "recommended_videos": youtube_videos,
                "daily_quote": self.get_daily_quote()
            }
            
        except Exception as e:
            logger.error(f"Error getting personalized content: {str(e)}")
            return {}
    
    def get_youtube_recommendations(self, topics: List[str] = None, max_results: int = 10) -> List[Dict]:
        """Get YouTube video recommendations based on topics"""
        try:
            if not topics:
                # Get popular topics from database
                popular_topics = self.db.get_popular_topics(limit=5)
                topics = [topic["topic"] for topic in popular_topics]
            
            videos = self.youtube_service.get_recommended_videos(topics, max_results)
            
            # Format duration for each video
            for video in videos:
                video["formatted_duration"] = self.youtube_service.format_duration(video.get("duration", "PT0S"))
            
            return videos
            
        except Exception as e:
            logger.error(f"Error getting YouTube recommendations: {str(e)}")
            return []
    
    def schedule_content_generation(self):
        """Schedule regular content generation (can be called by a cron job)"""
        try:
            logger.info("Starting scheduled content generation")
            
            # Generate articles
            articles = self.generate_content_from_chats("article")
            logger.info(f"Generated {len(articles)} articles")
            
            # Generate video scripts
            videos = self.generate_content_from_chats("video")
            logger.info(f"Generated {len(videos)} video scripts")
            
            return {
                "articles_generated": len(articles),
                "videos_generated": len(videos)
            }
            
        except Exception as e:
            logger.error(f"Error in scheduled content generation: {str(e)}")
            return {"error": str(e)} 