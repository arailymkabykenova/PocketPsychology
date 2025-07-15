from pydantic import BaseModel
from enum import Enum
from typing import List, Optional


class ChatMode(str, Enum):
    """Enumeration for different chat modes"""
    SUPPORT = "support"
    ANALYSIS = "analysis"
    PRACTICE = "practice"


class ChatRequest(BaseModel):
    """Request model for chat endpoint"""
    message: str
    mode: ChatMode
    user_id: Optional[str] = "default"
    language: Optional[str] = "ru"


class ChatResponse(BaseModel):
    """Response model for chat endpoint"""
    response: str
    mode: ChatMode
    topic: Optional[str] = None
    topic_task_id: Optional[str] = None
    recommendations_task_id: Optional[str] = None


class ChatMessage(BaseModel):
    """Model for individual chat messages"""
    role: str  # "user" or "assistant"
    content: str
    timestamp: Optional[str] = None


class ChatHistory(BaseModel):
    """Model for chat history"""
    messages: List[ChatMessage] = [] 


class TopicExtractionRequest(BaseModel):
    """Request model for topic extraction"""
    message: str
    user_id: Optional[str] = "default"


class TopicExtractionResponse(BaseModel):
    """Response model for topic extraction"""
    topic: str
    user_id: str
    task_id: str


class TaskStatusResponse(BaseModel):
    """Response model for task status"""
    task_id: str
    status: str
    result: Optional[dict] = None
    error: Optional[str] = None 