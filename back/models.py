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


class ChatResponse(BaseModel):
    """Response model for chat endpoint"""
    response: str
    mode: ChatMode


class ChatMessage(BaseModel):
    """Model for individual chat messages"""
    role: str  # "user" or "assistant"
    content: str
    timestamp: Optional[str] = None


class ChatHistory(BaseModel):
    """Model for chat history"""
    messages: List[ChatMessage] = [] 