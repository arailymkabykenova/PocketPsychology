import os
import logging
from typing import Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from models import ChatRequest, ChatResponse, ChatMode
from ai_service import AIService

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
except Exception as e:
    print(f"=== ERROR initializing AI service: {type(e).__name__}: {str(e)} ===")
    logger.error(f"Failed to initialize AI service: {str(e)}")
    ai_service = None


@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "AI Chatbot API is running", "status": "healthy"}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Main chat endpoint that processes user messages and returns AI responses
    
    Args:
        request: ChatRequest containing message and mode
        
    Returns:
        ChatResponse with AI response and mode
    """
    try:
        if ai_service is None:
            raise HTTPException(status_code=500, detail="AI service not available")
        
        # Validate input
        if not request.message.strip():
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        logger.info(f"Processing chat request - Mode: {request.mode}, Message: {request.message[:50]}...")
        
        # Get AI response
        ai_response = await ai_service.get_response(request.message, request.mode)
        
        logger.info(f"AI response generated successfully for mode: {request.mode}")
        
        return ChatResponse(
            response=ai_response,
            mode=request.mode
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/health")
async def health_check():
    """Detailed health check endpoint"""
    return {
        "status": "healthy",
        "ai_service": "available" if ai_service else "unavailable",
        "environment": {
            "azure_endpoint": bool(os.getenv("AZURE_OPENAI_ENDPOINT")),
            "azure_api_key": bool(os.getenv("AZURE_OPENAI_API_KEY")),
            "deployment_name": bool(os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"))
        }
    }


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


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", 8000)),
        reload=True
    ) 