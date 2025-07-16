import sqlite3
import json
import logging
from datetime import datetime
from typing import List, Dict, Optional
from pathlib import Path

logger = logging.getLogger(__name__)

class Database:
    def __init__(self, db_path: str = "chatbot.db"):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize database with required tables"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Conversations table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS conversations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    mode TEXT NOT NULL,
                    role TEXT NOT NULL,
                    content TEXT NOT NULL,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Topics table for content generation
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS topics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    topic TEXT NOT NULL,
                    frequency INTEGER DEFAULT 1,
                    last_mentioned DATETIME DEFAULT CURRENT_TIMESTAMP,
                    mode TEXT NOT NULL
                )
            ''')
            
            # Generated content table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS generated_content (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    content_type TEXT NOT NULL,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL,
                    source_topics TEXT,
                    approach TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    is_active BOOLEAN DEFAULT 1
                )
            ''')
            
            # Add approach column if it doesn't exist (for existing databases)
            try:
                cursor.execute('ALTER TABLE generated_content ADD COLUMN approach TEXT')
                logger.info("Added approach column to generated_content table")
            except sqlite3.OperationalError:
                # Column already exists
                pass
            
            # Quotes table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS quotes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    text TEXT NOT NULL,
                    author TEXT NOT NULL,
                    topic TEXT NOT NULL,
                    language TEXT DEFAULT 'ru',
                    is_generated BOOLEAN DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    is_active BOOLEAN DEFAULT 1
                )
            ''')
            
            # User sessions table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS user_sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT UNIQUE NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    last_activity DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            conn.commit()
            logger.info("Database initialized successfully")
    
    def save_message(self, user_id: str, mode: str, role: str, content: str):
        """Save a message to the database"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO conversations (user_id, mode, role, content)
                VALUES (?, ?, ?, ?)
            ''', (user_id, mode, role, content))
            
            # Update user session
            cursor.execute('''
                INSERT OR REPLACE INTO user_sessions (user_id, last_activity)
                VALUES (?, CURRENT_TIMESTAMP)
            ''', (user_id,))
            
            conn.commit()
    
    def get_conversation_history(self, user_id: str, mode: str, limit: int = 20) -> List[Dict]:
        """Get conversation history for a user and mode"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT role, content, timestamp
                FROM conversations
                WHERE user_id = ? AND mode = ?
                ORDER BY timestamp DESC
                LIMIT ?
            ''', (user_id, mode, limit))
            
            rows = cursor.fetchall()
            return [
                {"role": row[0], "content": row[1], "timestamp": row[2]}
                for row in reversed(rows)  # Reverse to get chronological order
            ]
    
    def clear_conversation_history(self, user_id: str, mode: Optional[str] = None):
        """Clear conversation history for a user"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            if mode:
                cursor.execute('''
                    DELETE FROM conversations
                    WHERE user_id = ? AND mode = ?
                ''', (user_id, mode))
            else:
                cursor.execute('''
                    DELETE FROM conversations
                    WHERE user_id = ?
                ''', (user_id,))
            conn.commit()
    
    def extract_topics(self, content: str, mode: str):
        """Extract and save topics from conversation content"""
        # Simple topic extraction (can be enhanced with NLP)
        import re
        
        # Common psychological topics
        topics = [
            "стресс", "тревога", "депрессия", "страх", "гнев", "грусть",
            "радость", "любовь", "отношения", "работа", "семья", "друзья",
            "здоровье", "сон", "еда", "спорт", "медитация", "дыхание",
            "stress", "anxiety", "depression", "fear", "anger", "sadness",
            "joy", "love", "relationships", "work", "family", "friends",
            "health", "sleep", "food", "exercise", "meditation", "breathing"
        ]
        
        found_topics = []
        content_lower = content.lower()
        
        for topic in topics:
            if topic in content_lower:
                found_topics.append(topic)
        
        # Save found topics
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            for topic in found_topics:
                cursor.execute('''
                    INSERT OR REPLACE INTO topics (topic, mode, frequency, last_mentioned)
                    VALUES (?, ?, 
                        COALESCE((SELECT frequency + 1 FROM topics WHERE topic = ? AND mode = ?), 1),
                        CURRENT_TIMESTAMP)
                ''', (topic, mode, topic, mode))
            conn.commit()
    
    def get_popular_topics(self, mode: Optional[str] = None, limit: int = 10) -> List[Dict]:
        """Get most popular topics for content generation"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            if mode:
                cursor.execute('''
                    SELECT topic, frequency, last_mentioned
                    FROM topics
                    WHERE mode = ?
                    ORDER BY frequency DESC, last_mentioned DESC
                    LIMIT ?
                ''', (mode, limit))
            else:
                cursor.execute('''
                    SELECT topic, frequency, last_mentioned
                    FROM topics
                    ORDER BY frequency DESC, last_mentioned DESC
                    LIMIT ?
                ''', (limit,))
            
            rows = cursor.fetchall()
            return [
                {"topic": row[0], "frequency": row[1], "last_mentioned": row[2]}
                for row in rows
            ]
    
    def get_all_topics(self, limit: int = 50) -> List[Dict]:
        """Get all active topics from the database"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT topic, frequency, last_mentioned, mode
                FROM topics
                WHERE is_active IS NULL OR is_active = 1
                ORDER BY frequency DESC, last_mentioned DESC
                LIMIT ?
            ''', (limit,))
            
            rows = cursor.fetchall()
            return [
                {"topic": row[0], "frequency": row[1], "last_mentioned": row[2], "mode": row[3]}
                for row in rows
            ]
    
    def save_generated_content(self, content_type: str, title: str, content: str, source_topics: List[str], approach: str):
        """Save generated content (articles, videos)"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO generated_content (content_type, title, content, source_topics, approach)
                VALUES (?, ?, ?, ?, ?)
            ''', (content_type, title, content, json.dumps(source_topics), approach))
            conn.commit()
    
    def get_generated_content(self, content_type: str, limit: int = 10) -> List[Dict]:
        """Get generated content of specific type"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT title, content, source_topics, created_at, approach
                FROM generated_content
                WHERE content_type = ? AND is_active = 1
                ORDER BY created_at DESC
                LIMIT ?
            ''', (content_type, limit))
            
            rows = cursor.fetchall()
            return [
                {
                    "title": row[0],
                    "content": row[1],
                    "source_topics": json.loads(row[2]) if row[2] else [],
                    "created_at": row[3],
                    "approach": row[4]
                }
                for row in rows
            ]
    
    def get_articles_grouped_by_topic(self, topics: List[str] = None, limit_per_topic: int = 3) -> List[Dict]:
        """
        Get articles grouped by topic, ensuring each topic has up to 3 articles (practical, theoretical, motivational)
        If topics is None, returns articles for all available topics
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            if topics:
                # Get all articles for all topics, filter in Python
                cursor.execute('''
                    SELECT title, content, source_topics, created_at, approach
                    FROM generated_content
                    WHERE content_type = 'article' AND is_active = 1
                    ORDER BY source_topics, approach, created_at DESC
                ''')
                rows = cursor.fetchall()
                # Фильтруем только те, где нужный топик реально есть в source_topics
                filtered_rows = []
                for row in rows:
                    source_topics = json.loads(row[2]) if row[2] else []
                    if any(t.lower() == s.lower() for s in source_topics for t in topics):
                        filtered_rows.append(row)
                rows = filtered_rows
            else:
                # Get articles for all topics
                cursor.execute('''
                    SELECT title, content, source_topics, created_at, approach
                    FROM generated_content
                    WHERE content_type = 'article' AND is_active = 1
                    ORDER BY source_topics, approach, created_at DESC
                ''')
                rows = cursor.fetchall()
            
            # Group articles by topic and approach
            articles_by_topic = {}
            for row in rows:
                source_topics = json.loads(row[2]) if row[2] else []
                if source_topics:
                    topic = source_topics[0]  # Take first topic
                    approach = row[4] or "practical"
                    
                    if topic not in articles_by_topic:
                        articles_by_topic[topic] = {}
                    
                    if approach not in articles_by_topic[topic]:
                        articles_by_topic[topic][approach] = []
                    
                    article = {
                        "title": row[0],
                        "content": row[1],
                        "source_topics": source_topics,
                        "created_at": row[3],
                        "approach": approach,
                        "topic": topic
                    }
                    
                    articles_by_topic[topic][approach].append(article)
            
            # Select up to limit_per_topic articles per topic, prioritizing different approaches
            result = []
            for topic, approaches in articles_by_topic.items():
                topic_articles = []
                
                # Try to get one article of each approach type
                for approach in ["practical", "theoretical", "motivational"]:
                    if approach in approaches and approaches[approach]:
                        topic_articles.append(approaches[approach][0])  # Take the most recent
                
                # If we don't have all 3 approaches, fill with available ones
                for approach, articles in approaches.items():
                    if len(topic_articles) < limit_per_topic and approach not in [a["approach"] for a in topic_articles]:
                        for article in articles:
                            if len(topic_articles) < limit_per_topic:
                                topic_articles.append(article)
                            else:
                                break
                
                result.extend(topic_articles)
            
            return result
    
    def get_user_stats(self, user_id: str) -> Dict:
        """Get user conversation statistics"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Total messages
            cursor.execute('''
                SELECT COUNT(*) FROM conversations WHERE user_id = ?
            ''', (user_id,))
            total_messages = cursor.fetchone()[0]
            
            # Messages by mode
            cursor.execute('''
                SELECT mode, COUNT(*) 
                FROM conversations 
                WHERE user_id = ? 
                GROUP BY mode
            ''', (user_id,))
            messages_by_mode = dict(cursor.fetchall())
            
            # Last activity
            cursor.execute('''
                SELECT last_activity FROM user_sessions WHERE user_id = ?
            ''', (user_id,))
            last_activity = cursor.fetchone()
            
            return {
                "total_messages": total_messages,
                "messages_by_mode": messages_by_mode,
                "last_activity": last_activity[0] if last_activity else None
            }
    
    def save_quote(self, text: str, author: str, topic: str, language: str = "ru", is_generated: bool = False):
        """Save a quote to the database"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO quotes (text, author, topic, language, is_generated)
                VALUES (?, ?, ?, ?, ?)
            ''', (text, author, topic, language, is_generated))
            conn.commit()
    
    def get_quotes(self, topic: Optional[str] = None, language: str = "ru", limit: int = 10) -> List[Dict]:
        """Get quotes from database"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            if topic:
                cursor.execute('''
                    SELECT text, author, topic, language, created_at
                    FROM quotes
                    WHERE topic = ? AND language = ? AND is_active = 1
                    ORDER BY RANDOM()
                    LIMIT ?
                ''', (topic, language, limit))
            else:
                cursor.execute('''
                    SELECT text, author, topic, language, created_at
                    FROM quotes
                    WHERE language = ? AND is_active = 1
                    ORDER BY RANDOM()
                    LIMIT ?
                ''', (language, limit))
            
            rows = cursor.fetchall()
            return [
                {
                    "text": row[0],
                    "author": row[1],
                    "topic": row[2],
                    "language": row[3],
                    "created_at": row[4]
                }
                for row in rows
            ]
    
    def get_daily_quote(self, language: str = "ru") -> Optional[Dict]:
        """Get a quote for today based on day of year"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Get total number of quotes
            cursor.execute('''
                SELECT COUNT(*) FROM quotes WHERE language = ? AND is_active = 1
            ''', (language,))
            total_quotes = cursor.fetchone()[0]
            
            if total_quotes == 0:
                return None
            
            # Use day of year to select quote
            day_of_year = datetime.now().timetuple().tm_yday
            quote_index = day_of_year % total_quotes
            
            cursor.execute('''
                SELECT text, author, topic, language, created_at
                FROM quotes
                WHERE language = ? AND is_active = 1
                ORDER BY id
                LIMIT 1 OFFSET ?
            ''', (language, quote_index))
            
            row = cursor.fetchone()
            if row:
                return {
                    "text": row[0],
                    "author": row[1],
                    "topic": row[2],
                    "language": row[3],
                    "created_at": row[4],
                    "date": datetime.now().strftime("%Y-%m-%d")
                }
            
            return None
    
    def get_quotes_by_topic(self, topic: str, language: str = "ru", limit: int = 5) -> List[Dict]:
        """Get quotes for a specific topic"""
        return self.get_quotes(topic=topic, language=language, limit=limit)
    
    def populate_default_quotes(self):
        """Populate database with default quotes if empty"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Check if quotes table is empty
            cursor.execute('SELECT COUNT(*) FROM quotes')
            count = cursor.fetchone()[0]
            
            if count == 0:
                # Russian quotes
                russian_quotes = [
                    ("Будь изменением, которое ты хочешь видеть в мире", "Махатма Ганди", "мотивация"),
                    ("Каждый день - это новая возможность стать лучше", "Неизвестный", "мотивация"),
                    ("Счастье не в том, чтобы делать всегда, что хочешь, а в том, чтобы всегда хотеть того, что делаешь", "Лев Толстой", "счастье"),
                    ("Самое важное - это не то, что с нами происходит, а то, как мы на это реагируем", "Эпиктет", "отношения"),
                    ("Успех - это способность шагать от одной неудачи к другой, не теряя энтузиазма", "Уинстон Черчилль", "успех"),
                    ("Лучший способ предсказать будущее - создать его", "Питер Друкер", "будущее"),
                    ("Ты не можешь контролировать все, что происходит с тобой, но ты можешь контролировать свою реакцию", "Неизвестный", "контроль"),
                    ("Каждый опыт, даже негативный, делает тебя сильнее", "Неизвестный", "опыт"),
                    ("Вера в себя - это первый шаг к успеху", "Неизвестный", "вера"),
                    ("Терпение - это не способность ждать, а способность сохранять хорошее настроение во время ожидания", "Неизвестный", "терпение")
                ]
                
                # English quotes
                english_quotes = [
                    ("Be the change you wish to see in the world", "Mahatma Gandhi", "motivation"),
                    ("Every day is a new opportunity to become better", "Unknown", "motivation"),
                    ("Happiness is not in always doing what you want, but in always wanting what you do", "Leo Tolstoy", "happiness"),
                    ("The most important thing is not what happens to us, but how we react to it", "Epictetus", "relationships"),
                    ("Success is the ability to go from one failure to another with no loss of enthusiasm", "Winston Churchill", "success"),
                    ("The best way to predict the future is to create it", "Peter Drucker", "future"),
                    ("You cannot control everything that happens to you, but you can control your reaction", "Unknown", "control"),
                    ("Every experience, even negative, makes you stronger", "Unknown", "experience"),
                    ("Belief in yourself is the first step to success", "Unknown", "belief"),
                    ("Patience is not the ability to wait, but the ability to keep a good attitude while waiting", "Unknown", "patience")
                ]
                
                # Insert Russian quotes
                cursor.executemany('''
                    INSERT INTO quotes (text, author, topic, language, is_generated)
                    VALUES (?, ?, ?, 'ru', 0)
                ''', russian_quotes)
                
                # Insert English quotes
                cursor.executemany('''
                    INSERT INTO quotes (text, author, topic, language, is_generated)
                    VALUES (?, ?, ?, 'en', 0)
                ''', english_quotes)
                
                conn.commit()
                logger.info(f"Populated database with {len(russian_quotes)} Russian and {len(english_quotes)} English default quotes")

    def update_user_current_topic(self, user_id: str, topic: Optional[str]):
        """Update or create user's current topic"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Create user_topics table if it doesn't exist
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS user_topics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT UNIQUE NOT NULL,
                    current_topic TEXT NULL,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            if topic is None:
                # Delete user's current topic
                cursor.execute('''
                    DELETE FROM user_topics WHERE user_id = ?
                ''', (user_id,))
                logger.info(f"Cleared current topic for user {user_id}")
            else:
                # Insert or update user's current topic
                cursor.execute('''
                    INSERT OR REPLACE INTO user_topics (user_id, current_topic, updated_at)
                    VALUES (?, ?, CURRENT_TIMESTAMP)
                ''', (user_id, topic))
                logger.info(f"Updated current topic '{topic}' for user {user_id}")
            
            conn.commit()

    def get_user_current_topic(self, user_id: str) -> Optional[str]:
        """Get user's current topic"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Create user_topics table if it doesn't exist
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS user_topics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT UNIQUE NOT NULL,
                    current_topic TEXT NULL,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            cursor.execute('''
                SELECT current_topic
                FROM user_topics
                WHERE user_id = ?
            ''', (user_id,))
            
            row = cursor.fetchone()
            return row[0] if row else None

    def get_user_recent_topics(self, user_id: str, limit: int = 5) -> List[str]:
        """Get user's recent topics from conversation history"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Get recent user messages and extract topics
            cursor.execute('''
                SELECT content
                FROM conversations
                WHERE user_id = ? AND role = 'user'
                ORDER BY timestamp DESC
                LIMIT ?
            ''', (user_id, limit * 2))  # Get more messages to extract topics
            
            messages = [row[0] for row in cursor.fetchall()]
            
            # Extract topics from messages
            topics = []
            for message in messages:
                message_topics = self.extract_topics_from_text(message)
                topics.extend(message_topics)
            
            # Return unique topics
            return list(set(topics))[:limit]

    def extract_topics_from_text(self, text: str) -> List[str]:
        """Extract topics from text (simplified version)"""
        # Common psychological topics
        topics = [
            "стресс", "тревога", "депрессия", "страх", "гнев", "грусть",
            "радость", "любовь", "отношения", "работа", "семья", "друзья",
            "здоровье", "сон", "еда", "спорт", "медитация", "дыхание",
            "мотивация", "уверенность", "самооценка", "цели", "планы",
            "stress", "anxiety", "depression", "fear", "anger", "sadness",
            "joy", "love", "relationships", "work", "family", "friends",
            "health", "sleep", "food", "exercise", "meditation", "breathing",
            "motivation", "confidence", "self-esteem", "goals", "plans"
        ]
        
        found_topics = []
        text_lower = text.lower()
        
        for topic in topics:
            if topic in text_lower:
                found_topics.append(topic)
        
        return found_topics

    def get_user_topic_history(self, user_id: str, days: int = 7) -> List[Dict]:
        """Get user's topic history for the last N days"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT topic, created_at
                FROM user_topics
                WHERE user_id = ? AND created_at >= datetime('now', '-{} days')
                ORDER BY created_at DESC
            '''.format(days), (user_id,))
            
            rows = cursor.fetchall()
            return [
                {
                    "topic": row[0],
                    "created_at": row[1]
                }
                for row in rows
            ]
    
    def delete_user_account(self, user_id: str) -> bool:
        """Delete user account and all associated data"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Check if user exists
                cursor.execute('SELECT COUNT(*) FROM conversations WHERE user_id = ?', (user_id,))
                user_exists = cursor.fetchone()[0] > 0
                
                if not user_exists:
                    return False
                
                # Delete all user data
                tables_to_clean = [
                    'conversations',
                    'user_sessions', 
                    'user_topics'
                ]
                
                for table in tables_to_clean:
                    cursor.execute(f'DELETE FROM {table} WHERE user_id = ?', (user_id,))
                
                conn.commit()
                logger.info(f"Deleted user account data for user_id: {user_id}")
                return True
                
        except Exception as e:
            logger.error(f"Error deleting user account {user_id}: {e}")
            return False 