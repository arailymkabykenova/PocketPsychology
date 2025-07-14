# AI Chatbot Backend

FastAPI backend for AI chatbot with three conversation modes.

## Setup

1. **Create virtual environment:**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install dependencies:**
```bash
pip install -r requirements.txt
```

3. **Configure environment variables:**
```bash
cp env.example .env
# Edit .env file with your Azure OpenAI credentials
```

4. **Required environment variables:**
- `AZURE_OPENAI_ENDPOINT`: Your Azure OpenAI endpoint
- `AZURE_OPENAI_API_KEY`: Your Azure OpenAI API key
- `AZURE_OPENAI_DEPLOYMENT_NAME`: Your deployment name

## Running the Server

```bash
# From the back directory
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Or:
```bash
python main.py
```

## API Endpoints

- `GET /`: Health check
- `GET /health`: Detailed health check
- `POST /chat`: Main chat endpoint

## Chat Modes

1. **Support**: Empathetic listening without advice
2. **Analysis**: Socratic dialogue for self-reflection
3. **Practice**: CBT techniques and practical advice

## Testing

Visit `http://localhost:8000/docs` for interactive API documentation. 