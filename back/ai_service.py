import os
import logging
from typing import Optional, Dict, List
from openai import AzureOpenAI
from dotenv import load_dotenv
from models import ChatMode
from prompts import (
    SUPPORT_MODE_PROMPT_EN, SUPPORT_MODE_PROMPT_RU,
    ANALYSIS_MODE_PROMPT_EN, ANALYSIS_MODE_PROMPT_RU,
    PRACTICE_MODE_PROMPT_EN, PRACTICE_MODE_PROMPT_RU
)
from database import Database

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AIService:
    """Service for handling Azure OpenAI interactions with conversation memory"""
    
    def __init__(self):
        """Initialize Azure OpenAI client"""
        endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
        api_key = os.getenv("AZURE_OPENAI_API_KEY")
        deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME")
        
        if not all([endpoint, api_key, deployment_name]):
            missing = []
            if not endpoint: missing.append("AZURE_OPENAI_ENDPOINT")
            if not api_key: missing.append("AZURE_OPENAI_API_KEY")
            if not deployment_name: missing.append("AZURE_OPENAI_DEPLOYMENT_NAME")
            raise ValueError(f"Missing required Azure OpenAI environment variables: {', '.join(missing)}")
        
        # Create client with minimal parameters to avoid proxy issues
        self.client = AzureOpenAI(
            azure_endpoint=endpoint,
            api_key=api_key,
            api_version="2024-02-15-preview"
        )
        self.deployment_name = deployment_name
        
        # Initialize database
        self.db = Database()
        
        # Populate default quotes on first run
        self.db.populate_default_quotes()
        
        # Keep in-memory history for backward compatibility
        self.conversation_history: Dict[str, List[Dict[str, str]]] = {}
    
    def _get_system_prompt(self, mode: ChatMode, language: str = "ru") -> str:
        """Get the appropriate system prompt based on chat mode and language"""
        if language == "ru":
            prompts = {
                ChatMode.SUPPORT: SUPPORT_MODE_PROMPT_RU,
                ChatMode.ANALYSIS: ANALYSIS_MODE_PROMPT_RU,
                ChatMode.PRACTICE: PRACTICE_MODE_PROMPT_RU
            }
        else:
            prompts = {
                ChatMode.SUPPORT: SUPPORT_MODE_PROMPT_EN,
                ChatMode.ANALYSIS: ANALYSIS_MODE_PROMPT_EN,
                ChatMode.PRACTICE: PRACTICE_MODE_PROMPT_EN
            }
        return prompts.get(mode, SUPPORT_MODE_PROMPT_RU if language == "ru" else SUPPORT_MODE_PROMPT_EN)
    
    def _get_conversation_key(self, mode: ChatMode) -> str:
        """Generate a unique key for each conversation mode"""
        return f"conversation_{mode.value}"
    
    def _add_to_history(self, mode: ChatMode, role: str, content: str):
        """Add message to conversation history"""
        key = self._get_conversation_key(mode)
        if key not in self.conversation_history:
            self.conversation_history[key] = []
        
        self.conversation_history[key].append({
            "role": role,
            "content": content
        })
        
        # Keep only last 20 messages to avoid token limits
        if len(self.conversation_history[key]) > 20:
            self.conversation_history[key] = self.conversation_history[key][-20:]
    
    def _get_conversation_messages(self, mode: ChatMode, user_message: str, language: str = "ru") -> List[Dict[str, str]]:
        """Build conversation messages with history"""
        key = self._get_conversation_key(mode)
        messages = [{"role": "system", "content": self._get_system_prompt(mode, language)}]
        
        # Add conversation history
        if key in self.conversation_history:
            messages.extend(self.conversation_history[key])
        
        # Add current user message
        messages.append({"role": "user", "content": user_message})
        
        return messages
    
    def _detect_language(self, message: str) -> str:
        """Detect language from user message"""
        # Simple language detection based on character sets
        cyrillic_chars = sum(1 for char in message if '\u0400' <= char <= '\u04FF')
        latin_chars = sum(1 for char in message if char.isalpha() and ord(char) < 128)
        
        logger.info(f"Language detection - Cyrillic chars: {cyrillic_chars}, Latin chars: {latin_chars}")
        
        # If more than 50% of characters are Cyrillic, assume Russian
        if cyrillic_chars > latin_chars and cyrillic_chars > 0:
            detected = "ru"
        else:
            detected = "en"
        
        logger.info(f"Language detected: {detected} for message: '{message[:50]}...'")
        return detected
    
    async def get_response(self, message: str, mode: ChatMode, user_id: str = "default", language: str = "ru") -> Dict:
        """
        Get AI response based on user message and selected mode with conversation memory
        Now returns both response and topic for automatic content updates
        
        Args:
            message: User's input message
            mode: Selected conversation mode
            user_id: User identifier for database storage
            language: Language for content generation (ru/en)
            
        Returns:
            Dict containing AI response and extracted topic
        """
        try:
            # Auto-detect language from user message if not explicitly provided
            detected_language = self._detect_language(message)
            if language == "ru":  # Only override if user explicitly set Russian
                final_language = language
            else:
                final_language = detected_language
            
            logger.info(f"Language detection: requested={language}, detected={detected_language}, final={final_language}")
            
            # Save user message to database
            self.db.save_message(user_id, mode.value, "user", message)
            
            # Extract topics from user message
            self.db.extract_topics(message, mode.value)
            
            # Add user message to history (backward compatibility)
            self._add_to_history(mode, "user", message)
            
            # Get conversation messages with history
            messages = self._get_conversation_messages(mode, message, final_language)
            
            response = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=messages,
                max_tokens=600,
                temperature=0.7
            )
            
            ai_response = response.choices[0].message.content
            logger.info(f"AI response generated for mode: {mode}")
            
            # Save AI response to database
            self.db.save_message(user_id, mode.value, "assistant", ai_response)
            
            # Add AI response to history (backward compatibility)
            self._add_to_history(mode, "assistant", ai_response)
            
            # Import tasks here to avoid circular import
            from tasks import extract_topic_from_message, update_user_recommendations, get_cached_topic
            
            # Extract topic asynchronously using Celery with detected language
            topic_task = extract_topic_from_message.delay(message, user_id, final_language)
            
            # Update user recommendations asynchronously with detected language
            recommendations_task = update_user_recommendations.delay(user_id, final_language)
            
            # Get cached topic if available, otherwise return None (will be updated by task)
            cached_topic = get_cached_topic(user_id)
            logger.info(f"Retrieved cached topic for user {user_id}: '{cached_topic}'")
            
            return {
                "response": ai_response,
                "mode": mode.value,
                "topic": cached_topic,
                "topic_task_id": topic_task.id,
                "recommendations_task_id": recommendations_task.id
            }
            
        except Exception as e:
            logger.error(f"Error getting AI response: {str(e)}")
            return {
                "response": f"Sorry, I'm having trouble responding right now. Please try again later. (Error: {str(e)})",
                "mode": mode.value,
                "topic": None,
                "error": str(e)
            }
    
    def clear_conversation_history(self, mode: Optional[ChatMode] = None):
        """Clear conversation history for specific mode or all modes"""
        if mode:
            key = self._get_conversation_key(mode)
            if key in self.conversation_history:
                del self.conversation_history[key]
                logger.info(f"Cleared conversation history for mode: {mode}")
        else:
            self.conversation_history.clear()
            logger.info("Cleared all conversation history") 