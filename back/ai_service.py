import os
import logging
from typing import Optional, Dict, List
from openai import AzureOpenAI
from models import ChatMode
from prompts import SUPPORT_MODE_PROMPT, ANALYSIS_MODE_PROMPT, PRACTICE_MODE_PROMPT

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
        
        # Conversation history storage
        self.conversation_history: Dict[str, List[Dict[str, str]]] = {}
    
    def _get_system_prompt(self, mode: ChatMode) -> str:
        """Get the appropriate system prompt based on chat mode"""
        prompts = {
            ChatMode.SUPPORT: SUPPORT_MODE_PROMPT,
            ChatMode.ANALYSIS: ANALYSIS_MODE_PROMPT,
            ChatMode.PRACTICE: PRACTICE_MODE_PROMPT
        }
        return prompts.get(mode, SUPPORT_MODE_PROMPT)
    
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
    
    def _get_conversation_messages(self, mode: ChatMode, user_message: str) -> List[Dict[str, str]]:
        """Build conversation messages with history"""
        key = self._get_conversation_key(mode)
        messages = [{"role": "system", "content": self._get_system_prompt(mode)}]
        
        # Add conversation history
        if key in self.conversation_history:
            messages.extend(self.conversation_history[key])
        
        # Add current user message
        messages.append({"role": "user", "content": user_message})
        
        return messages
    
    async def get_response(self, message: str, mode: ChatMode) -> str:
        """
        Get AI response based on user message and selected mode with conversation memory
        
        Args:
            message: User's input message
            mode: Selected conversation mode
            
        Returns:
            AI response string
        """
        try:
            # Add user message to history
            self._add_to_history(mode, "user", message)
            
            # Get conversation messages with history
            messages = self._get_conversation_messages(mode, message)
            
            response = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=messages,
                max_tokens=600,
                temperature=0.7
            )
            
            ai_response = response.choices[0].message.content
            logger.info(f"AI response generated for mode: {mode}")
            
            # Add AI response to history
            self._add_to_history(mode, "assistant", ai_response)
            
            return ai_response
            
        except Exception as e:
            logger.error(f"Error getting AI response: {str(e)}")
            return f"Sorry, I'm having trouble responding right now. Please try again later. (Error: {str(e)})"
    
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