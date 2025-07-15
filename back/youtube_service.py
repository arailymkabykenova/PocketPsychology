import os
import logging
from typing import List, Dict, Optional
from datetime import datetime, timedelta
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

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
    
    def search_videos(self, query: str, max_results: int = 10, language: str = "ru") -> List[Dict]:
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
            return self._get_fallback_videos(query)
        
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
            
            logger.info(f"Found {len(videos)} videos for query: {query}")
            return videos
            
        except HttpError as e:
            logger.error(f"YouTube API error: {str(e)}")
            return self._get_fallback_videos(query, language)
        except Exception as e:
            logger.error(f"Error searching YouTube videos: {str(e)}")
            return self._get_fallback_videos(query, language)
    
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
                        "id": "dQw4w9WgXcQ",  # Example ID
                        "title": "How to Deal with Stress: 5 Effective Techniques",
                        "description": "Practical advice for managing stress in daily life",
                        "thumbnail": "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg",
                        "channel": "Psychology and Self-Help",
                        "duration": "PT8M30S",
                        "view_count": 150000,
                        "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
                    }
                ],
                "meditation": [
                    {
                        "id": "example2",
                        "title": "Meditation for Beginners: Step-by-Step Guide",
                        "description": "Simple meditation technique for those just starting out",
                        "thumbnail": "https://img.youtube.com/vi/example2/mqdefault.jpg",
                        "channel": "Meditation and Mindfulness",
                        "duration": "PT10M15S",
                        "view_count": 89000,
                        "url": "https://www.youtube.com/watch?v=example2"
                    }
                ],
                "motivation": [
                    {
                        "id": "example3",
                        "title": "How to Find Motivation and Achieve Goals",
                        "description": "Practical tips for increasing motivation",
                        "thumbnail": "https://img.youtube.com/vi/example3/mqdefault.jpg",
                        "channel": "Personal Growth",
                        "duration": "PT12M45S",
                        "view_count": 234000,
                        "url": "https://www.youtube.com/watch?v=example3"
                    }
                ]
            }
            
            # Return default motivational videos in English
            default_video = {
                "id": "default1",
                "title": "How to Improve Quality of Life: Practical Tips",
                "description": "Simple steps to a happier and healthier life",
                "thumbnail": "https://img.youtube.com/vi/default1/mqdefault.jpg",
                "channel": "Psychology and Self-Help",
                "duration": "PT9M20S",
                "view_count": 125000,
                "url": "https://www.youtube.com/watch?v=default1"
            }
        else:
            fallback_videos = {
                "стресс": [
                    {
                        "id": "dQw4w9WgXcQ",  # Example ID
                        "title": "Как справиться со стрессом: 5 эффективных техник",
                        "description": "Практические советы для управления стрессом в повседневной жизни",
                        "thumbnail": "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg",
                        "channel": "Психология и самопомощь",
                        "duration": "PT8M30S",
                        "view_count": 150000,
                        "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
                    }
                ],
                "медитация": [
                    {
                        "id": "example2",
                        "title": "Медитация для начинающих: пошаговое руководство",
                        "description": "Простая техника медитации для тех, кто только начинает",
                        "thumbnail": "https://img.youtube.com/vi/example2/mqdefault.jpg",
                        "channel": "Медитация и осознанность",
                        "duration": "PT10M15S",
                        "view_count": 89000,
                        "url": "https://www.youtube.com/watch?v=example2"
                    }
                ],
                "мотивация": [
                    {
                        "id": "example3",
                        "title": "Как найти мотивацию и достичь целей",
                        "description": "Практические советы для повышения мотивации",
                        "thumbnail": "https://img.youtube.com/vi/example3/mqdefault.jpg",
                        "channel": "Личностный рост",
                        "duration": "PT12M45S",
                        "view_count": 234000,
                        "url": "https://www.youtube.com/watch?v=example3"
                    }
                ]
            }
            
            # Return default motivational videos in Russian
            default_video = {
                "id": "default1",
                "title": "Как улучшить качество жизни: практические советы",
                "description": "Простые шаги к более счастливой и здоровой жизни",
                "thumbnail": "https://img.youtube.com/vi/default1/mqdefault.jpg",
                "channel": "Психология и самопомощь",
                "duration": "PT9M20S",
                "view_count": 125000,
                "url": "https://www.youtube.com/watch?v=default1"
            }
        
        # Find best matching topic
        for topic, videos in fallback_videos.items():
            if topic in query.lower():
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