import os
import logging
from typing import List, Dict, Optional
from datetime import datetime, timedelta
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

logger = logging.getLogger(__name__)

class YouTubeService:
    """Service for searching and recommending YouTube videos"""
    
    def __init__(self):
        """Initialize YouTube API client"""
        api_key = os.getenv("YOUTUBE_API_KEY")
        if not api_key:
            logger.warning("YouTube API key not found. YouTube recommendations will be disabled.")
            self.api_key = None
            self.youtube = None
        else:
            self.api_key = api_key
            self.youtube = build('youtube', 'v3', developerKey=api_key)
        
        # Cache for YouTube API results
        self._cache = {}
        self._cache_duration = timedelta(hours=24)  # Cache for 24 hours
        self._quota_exceeded_time = None
        self._quota_exceeded_count = 0  # Track how many times quota was exceeded
        self._quota_retry_interval = timedelta(hours=6)  # Retry after 6 hours initially
        self._max_quota_retries = 2  # After 2 failures, wait longer
    
    def search_videos(self, query: str, max_results: int = 5, language: str = "ru") -> List[Dict]:
        """
        Search for YouTube videos based on query
        
        Args:
            query: Search query
            max_results: Maximum number of results
            language: Language for search (ru/en)
            
        Returns:
            List of video information
        """
        if not self.youtube:
            logger.warning("YouTube API key not found, returning empty videos")
            return []
        
        # Check cache first
        cache_key = f"{query}:{language}:{max_results}"
        if cache_key in self._cache:
            cache_entry = self._cache[cache_key]
            if datetime.now() - cache_entry['timestamp'] < self._cache_duration:
                logger.info(f"Returning cached videos for query: {query}")
                return cache_entry['videos']
        
        # Check if we recently hit quota exceeded
        if self._quota_exceeded_time:
            time_since_quota_exceeded = datetime.now() - self._quota_exceeded_time
            
            # Calculate retry interval based on failure count
            if self._quota_exceeded_count >= self._max_quota_retries:
                # After multiple failures, wait much longer (18 hours)
                retry_interval = timedelta(hours=18)
                logger.info(f"Using extended retry interval (18h) due to {self._quota_exceeded_count} quota failures")
            else:
                retry_interval = self._quota_retry_interval
            
            if time_since_quota_exceeded < retry_interval:
                logger.info(f"Returning empty videos due to recent quota exceeded for query: {query} (count: {self._quota_exceeded_count})")
                return []
        
        try:
            # Add language-specific keywords for better results
            enhanced_query = self._enhance_query(query, language)
            
            # Search for videos
            search_response = self.youtube.search().list(
                q=enhanced_query,
                part='id,snippet',
                maxResults=max_results,
                type='video',
                videoDuration='medium',  # 4-20 minutes
                relevanceLanguage=language,
                order='relevance'
            ).execute()
            
            videos = []
            for item in search_response.get('items', []):
                video_id = item['id']['videoId']
                
                # Get additional video details
                video_details = self._get_video_details(video_id)
                if video_details:
                    videos.append(video_details)
            
            # Cache successful results
            if videos:
                self._cache[cache_key] = {
                    'videos': videos,
                    'timestamp': datetime.now()
                }
                logger.info(f"Found and cached {len(videos)} videos for query: {query}")
                
                # Reset quota exceeded counter on successful API call
                if self._quota_exceeded_count > 0:
                    logger.info(f"Resetting quota exceeded counter from {self._quota_exceeded_count} to 0 after successful API call")
                    self._quota_exceeded_count = 0
                    self._quota_exceeded_time = None
            
            return videos
            
        except HttpError as e:
            if "quotaExceeded" in str(e):
                self._quota_exceeded_count += 1
                self._quota_exceeded_time = datetime.now()
                
                if self._quota_exceeded_count >= self._max_quota_retries:
                    logger.warning(f"YouTube API quota exceeded (attempt {self._quota_exceeded_count}), returning empty videos for 18 hours for query: {query}")
                else:
                    logger.warning(f"YouTube API quota exceeded (attempt {self._quota_exceeded_count}), returning empty videos for 6 hours for query: {query}")
                
                return []
            else:
                logger.error(f"YouTube API error: {str(e)}")
                return []
        except Exception as e:
            logger.error(f"Error searching YouTube videos: {str(e)}")
            return []
    
    def _enhance_query(self, query: str, language: str) -> str:
        """Enhance search query with relevant keywords"""
        # Map topics to better search terms
        topic_mapping = {
            "стресс": "как справиться со стрессом техники релаксации",
            "тревога": "как избавиться от тревоги техники успокоения",
            "депрессия": "как бороться с депрессией самопомощь",
            "медитация": "медитация для начинающих техники медитации",
            "сон": "как улучшить сон техники засыпания",
            "мотивация": "мотивация самосовершенствование личностный рост",
            "stress": "how to deal with stress relaxation techniques",
            "anxiety": "how to overcome anxiety calming techniques",
            "depression": "how to fight depression self help",
            "meditation": "meditation for beginners meditation techniques",
            "sleep": "how to improve sleep sleep techniques",
            "motivation": "motivation self improvement personal growth"
        }
        
        enhanced = topic_mapping.get(query.lower(), query)
        
        # Add language-specific motivational keywords
        if language == "ru":
            enhanced += " самопомощь психология"
        else:
            enhanced += " self help psychology"
        
        return enhanced
    
    def _get_video_details(self, video_id: str) -> Optional[Dict]:
        """Get detailed information about a video"""
        try:
            response = self.youtube.videos().list(
                part='snippet,statistics,contentDetails',
                id=video_id
            ).execute()
            
            if not response.get('items'):
                return None
            
            video = response['items'][0]
            snippet = video['snippet']
            statistics = video.get('statistics', {})
            content_details = video.get('contentDetails', {})
            
            return {
                "id": video_id,
                "title": snippet['title'],
                "description": snippet['description'][:200] + "..." if len(snippet['description']) > 200 else snippet['description'],
                "thumbnail": snippet['thumbnails']['medium']['url'],
                "channel": snippet['channelTitle'],
                "published_at": snippet['publishedAt'],
                "duration": content_details.get('duration', 'PT0S'),
                "view_count": int(statistics.get('viewCount', 0)),
                "like_count": int(statistics.get('likeCount', 0)),
                "url": f"https://www.youtube.com/watch?v={video_id}"
            }
            
        except Exception as e:
            logger.error(f"Error getting video details for {video_id}: {str(e)}")
            return None
    
    def _get_fallback_videos(self, query: str, language: str = "ru") -> List[Dict]:
        """Return fallback videos when YouTube API is not available"""
        # Curated list of motivational and self-help videos based on language
        if language == "en":
            fallback_videos = {
                "stress": [
                    {
                        "id": "stress_help_1",
                        "title": "How to Deal with Stress: 5 Effective Techniques",
                        "description": "Practical advice for managing stress in daily life",
                        "thumbnail": "https://img.youtube.com/vi/stress_help_1/mqdefault.jpg",
                        "channel": "Psychology and Self-Help",
                        "duration": "PT8M30S",
                        "view_count": 150000,
                        "url": "https://www.youtube.com/watch?v=stress_help_1"
                    }
                ],
                "anxiety": [
                    {
                        "id": "anxiety_relief_1",
                        "title": "Anxiety Relief: Simple Techniques That Work",
                        "description": "Quick and effective methods to reduce anxiety",
                        "thumbnail": "https://img.youtube.com/vi/anxiety_relief_1/mqdefault.jpg",
                        "channel": "Mental Health Support",
                        "duration": "PT10M15S",
                        "view_count": 89000,
                        "url": "https://www.youtube.com/watch?v=anxiety_relief_1"
                    }
                ],
                "meditation": [
                    {
                        "id": "meditation_guide_1",
                        "title": "Meditation for Beginners: Step-by-Step Guide",
                        "description": "Simple meditation technique for those just starting out",
                        "thumbnail": "https://img.youtube.com/vi/meditation_guide_1/mqdefault.jpg",
                        "channel": "Meditation and Mindfulness",
                        "duration": "PT10M15S",
                        "view_count": 89000,
                        "url": "https://www.youtube.com/watch?v=meditation_guide_1"
                    }
                ],
                "motivation": [
                    {
                        "id": "motivation_tips_1",
                        "title": "How to Find Motivation and Achieve Goals",
                        "description": "Practical tips for increasing motivation",
                        "thumbnail": "https://img.youtube.com/vi/motivation_tips_1/mqdefault.jpg",
                        "channel": "Personal Growth",
                        "duration": "PT12M45S",
                        "view_count": 234000,
                        "url": "https://www.youtube.com/watch?v=motivation_tips_1"
                    }
                ],
                "relationship": [
                    {
                        "id": "relationship_advice_1",
                        "title": "Building Healthy Relationships: Communication Tips",
                        "description": "Learn effective communication skills for better relationships",
                        "thumbnail": "https://img.youtube.com/vi/relationship_advice_1/mqdefault.jpg",
                        "channel": "Relationship Counseling",
                        "duration": "PT11M25S",
                        "view_count": 189000,
                        "url": "https://www.youtube.com/watch?v=relationship_advice_1"
                    }
                ],
                "breakup": [
                    {
                        "id": "healing_breakup_1",
                        "title": "How to Heal After a Breakup: Practical Steps",
                        "description": "Step-by-step guide to emotional recovery after a relationship ends",
                        "thumbnail": "https://img.youtube.com/vi/healing_breakup_1/mqdefault.jpg",
                        "channel": "Emotional Wellness",
                        "duration": "PT9M45S",
                        "view_count": 156000,
                        "url": "https://www.youtube.com/watch?v=healing_breakup_1"
                    }
                ],
                "sleep": [
                    {
                        "id": "sleep_improvement_1",
                        "title": "How to Improve Your Sleep Quality",
                        "description": "Simple techniques for better sleep and rest",
                        "thumbnail": "https://img.youtube.com/vi/sleep_improvement_1/mqdefault.jpg",
                        "channel": "Sleep Science",
                        "duration": "PT7M30S",
                        "view_count": 112000,
                        "url": "https://www.youtube.com/watch?v=sleep_improvement_1"
                    }
                ]
            }
            
            # Return default motivational videos in English
            default_video = {
                "id": "self_help_guide_1",
                "title": "How to Improve Quality of Life: Practical Tips",
                "description": "Simple steps to a happier and healthier life",
                "thumbnail": "https://img.youtube.com/vi/self_help_guide_1/mqdefault.jpg",
                "channel": "Psychology and Self-Help",
                "duration": "PT9M20S",
                "view_count": 125000,
                "url": "https://www.youtube.com/watch?v=self_help_guide_1"
            }
        else:
            fallback_videos = {
                "стресс": [
                    {
                        "id": "stress_help_ru_1",
                        "title": "Как справиться со стрессом: 5 эффективных техник",
                        "description": "Практические советы для управления стрессом в повседневной жизни",
                        "thumbnail": "https://img.youtube.com/vi/stress_help_ru_1/mqdefault.jpg",
                        "channel": "Психология и самопомощь",
                        "duration": "PT8M30S",
                        "view_count": 150000,
                        "url": "https://www.youtube.com/watch?v=stress_help_ru_1"
                    }
                ],
                "тревога": [
                    {
                        "id": "anxiety_relief_ru_1",
                        "title": "Как избавиться от тревоги: простые техники",
                        "description": "Быстрые и эффективные методы для снижения тревоги",
                        "thumbnail": "https://img.youtube.com/vi/anxiety_relief_ru_1/mqdefault.jpg",
                        "channel": "Психологическая поддержка",
                        "duration": "PT10M15S",
                        "view_count": 89000,
                        "url": "https://www.youtube.com/watch?v=anxiety_relief_ru_1"
                    }
                ],
                "медитация": [
                    {
                        "id": "meditation_ru_1",
                        "title": "Медитация для начинающих: пошаговое руководство",
                        "description": "Простая техника медитации для тех, кто только начинает",
                        "thumbnail": "https://img.youtube.com/vi/meditation_ru_1/mqdefault.jpg",
                        "channel": "Медитация и осознанность",
                        "duration": "PT10M15S",
                        "view_count": 89000,
                        "url": "https://www.youtube.com/watch?v=meditation_ru_1"
                    }
                ],
                "мотивация": [
                    {
                        "id": "motivation_ru_1",
                        "title": "Как найти мотивацию и достичь целей",
                        "description": "Практические советы для повышения мотивации",
                        "thumbnail": "https://img.youtube.com/vi/motivation_ru_1/mqdefault.jpg",
                        "channel": "Личностный рост",
                        "duration": "PT12M45S",
                        "view_count": 234000,
                        "url": "https://www.youtube.com/watch?v=motivation_ru_1"
                    }
                ],
                "отношения": [
                    {
                        "id": "relationship_advice_ru_1",
                        "title": "Построение здоровых отношений: советы по общению",
                        "description": "Изучите эффективные навыки общения для лучших отношений",
                        "thumbnail": "https://img.youtube.com/vi/relationship_advice_ru_1/mqdefault.jpg",
                        "channel": "Консультации по отношениям",
                        "duration": "PT11M25S",
                        "view_count": 189000,
                        "url": "https://www.youtube.com/watch?v=relationship_advice_ru_1"
                    }
                ],
                "расставание": [
                    {
                        "id": "healing_breakup_ru_1",
                        "title": "Как исцелиться после расставания: практические шаги",
                        "description": "Пошаговое руководство по эмоциональному восстановлению после окончания отношений",
                        "thumbnail": "https://img.youtube.com/vi/healing_breakup_ru_1/mqdefault.jpg",
                        "channel": "Эмоциональное благополучие",
                        "duration": "PT9M45S",
                        "view_count": 156000,
                        "url": "https://www.youtube.com/watch?v=healing_breakup_ru_1"
                    }
                ],
                "сон": [
                    {
                        "id": "sleep_improvement_ru_1",
                        "title": "Как улучшить качество сна",
                        "description": "Простые техники для лучшего сна и отдыха",
                        "thumbnail": "https://img.youtube.com/vi/sleep_improvement_ru_1/mqdefault.jpg",
                        "channel": "Наука сна",
                        "duration": "PT7M30S",
                        "view_count": 112000,
                        "url": "https://www.youtube.com/watch?v=sleep_improvement_ru_1"
                    }
                ]
            }
            
            # Return default motivational videos in Russian
            default_video = {
                "id": "self_help_ru_1",
                "title": "Как улучшить качество жизни: практические советы",
                "description": "Простые шаги к более счастливой и здоровой жизни",
                "thumbnail": "https://img.youtube.com/vi/self_help_ru_1/mqdefault.jpg",
                "channel": "Психология и самопомощь",
                "duration": "PT9M20S",
                "view_count": 125000,
                "url": "https://www.youtube.com/watch?v=self_help_ru_1"
            }
        
        # Find best matching topic
        query_lower = query.lower()
        for topic, videos in fallback_videos.items():
            if topic in query_lower:
                return videos
        
        # Return default motivational videos
        return [default_video]
    
    def get_recommended_videos(self, topics: List[str], max_results: int = 5, language: str = "ru") -> List[Dict]:
        """
        Get recommended videos based on topics
        
        Args:
            topics: List of topics to search for
            max_results: Maximum number of results per topic
            language: Language for search (ru/en)
            
        Returns:
            List of recommended videos
        """
        all_videos = []
        
        for topic in topics:
            videos = self.search_videos(topic, max_results=max_results, language=language)
            all_videos.extend(videos)
        
        # Sort by relevance and popularity
        all_videos.sort(key=lambda x: x.get('view_count', 0), reverse=True)
        
        # Remove duplicates based on video ID
        seen_ids = set()
        unique_videos = []
        for video in all_videos:
            if video['id'] not in seen_ids:
                seen_ids.add(video['id'])
                unique_videos.append(video)
        
        return unique_videos[:max_results * len(topics)]
    
    def format_duration(self, duration: str) -> str:
        """Convert ISO 8601 duration to readable format"""
        try:
            # Parse ISO 8601 duration (PT8M30S)
            duration = duration.replace('PT', '')
            minutes = 0
            seconds = 0
            
            if 'H' in duration:
                hours = int(duration.split('H')[0])
                duration = duration.split('H')[1]
                minutes = hours * 60
            
            if 'M' in duration:
                minutes += int(duration.split('M')[0])
                duration = duration.split('M')[1]
            
            if 'S' in duration:
                seconds = int(duration.replace('S', ''))
            
            if minutes >= 60:
                hours = minutes // 60
                minutes = minutes % 60
                return f"{hours}:{minutes:02d}:{seconds:02d}"
            else:
                return f"{minutes}:{seconds:02d}"
                
        except Exception:
            return "0:00" 
    
    def clear_cache(self):
        """Clear the video cache"""
        self._cache.clear()
        logger.info("YouTube video cache cleared")
    
    def get_cache_status(self) -> Dict:
        """Get cache status information"""
        if self._quota_exceeded_time and isinstance(self._quota_exceeded_time, datetime):
            time_since_quota_exceeded = datetime.now() - self._quota_exceeded_time
            
            # Calculate current retry interval based on failure count
            if self._quota_exceeded_count >= self._max_quota_retries:
                current_retry_interval = timedelta(hours=18)
            else:
                current_retry_interval = self._quota_retry_interval
            
            quota_retry_available = time_since_quota_exceeded >= current_retry_interval
            time_until_retry = current_retry_interval - time_since_quota_exceeded
        else:
            quota_retry_available = True
            time_until_retry = None
        
        return {
            "cache_size": len(self._cache),
            "quota_exceeded_time": self._quota_exceeded_time.isoformat() if (self._quota_exceeded_time and isinstance(self._quota_exceeded_time, datetime)) else None,
            "quota_exceeded_count": self._quota_exceeded_count,
            "quota_retry_available": quota_retry_available,
            "time_until_retry_hours": time_until_retry.total_seconds() / 3600 if time_until_retry else None,
            "current_retry_interval_hours": 18 if self._quota_exceeded_count >= self._max_quota_retries else 6,
            "cache_duration_hours": self._cache_duration.total_seconds() / 3600,
            "max_quota_retries": self._max_quota_retries
        }
    
    def force_retry_youtube_api(self):
        """Force retry YouTube API by clearing quota exceeded flag"""
        self._quota_exceeded_time = None
        self._quota_exceeded_count = 0
        logger.info("YouTube API retry forced - quota exceeded flag and count cleared") 