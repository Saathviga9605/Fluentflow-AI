# Backend README

# 🧠 FluentFlow AI - Backend

Modern, clean, and scalable backend for an AI-powered English fluency assistant.

## 🚀 Quick Start

### Prerequisites
- Python 3.9+
- pip or conda

### Installation

1. **Create virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Create `.env` file (optional):**
   ```bash
   OPENAI_API_KEY=your_api_key_here
   USE_MOCK_LLM=False
   DEBUG=True
   ```

   If `.env` is not provided, the system uses mock responses by default.

### Run Server

```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server runs on: `http://localhost:8000`

## 📚 API Documentation

### Interactive Docs
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### Endpoints

#### 1. Health Check
```
GET /health
```

Returns service status and version.

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

---

#### 2. Full Conversation Analysis
```
POST /conversation
```

Accepts user text, analyzes fluency, generates correction, AI response, and feedback.

**Request:**
```json
{
  "user_text": "I like um, I think that good movie",
  "conversation_history": [
    {
      "role": "assistant",
      "content": "Hi! How are you today?"
    }
  ]
}
```

**Response:**
```json
{
  "original_text": "I like um, I think that good movie",
  "corrected_text": "I think that's a good movie",
  "response": "That's great! I'm glad you enjoyed it. What was your favorite part?",
  "follow_up_question": "Did you watch it in the theater or at home?",
  "fluency_feedback": {
    "filler_words": ["um"],
    "filler_count": 1,
    "fluency_score": 78.5,
    "hesitation_patterns": [],
    "grammar_issues": []
  },
  "tips": [
    "Try to reduce filler words like 'um' and 'uh' - take a breath instead!",
    "Good effort! You used 'good' - try more specific adjectives like 'great' or 'excellent'."
  ],
  "suggestions": [
    {
      "type": "synonym",
      "suggestion": "excellent",
      "explanation": "Alternative to 'good'"
    },
    {
      "type": "synonym",
      "suggestion": "wonderful",
      "explanation": "Alternative to 'good'"
    }
  ],
  "response_time_ms": 245.3
}
```

---

#### 3. Fluency Analysis Only
```
POST /analyze

#### 4. Speech to Text
```
POST /speech-to-text
```

Upload an audio file (`wav`, `mp3`, or similar supported by Whisper) and receive a transcript.

#### 5. Text to Speech
```
POST /text-to-speech
```

Send text and receive an audio response stream.

#### 6. Progress
```
GET /progress/{user_id}
```

Returns fluency trends, common errors, and score history.

#### 7. History
```
GET /history/{user_id}
```

Returns saved conversation history.
```

Returns only fluency analysis without AI response (faster).

**Request:**
```json
{
  "user_text": "I like um the food here"
}
```

**Response:**
```json
{
  "original_text": "I like um the food here",
  "fluency_feedback": {
    "filler_words": ["um"],
    "filler_count": 1,
    "fluency_score": 82.0,
    "hesitation_patterns": [],
    "grammar_issues": []
  },
  "suggestions": [
    {
      "type": "phrase",
      "suggestion": "I really like the food here",
      "explanation": "More natural phrasing"
    }
  ]
}
```

---

## 🧩 Architecture

### Folder Structure
```
backend/
├── app/
│   ├── main.py              # FastAPI app entry point
│   ├── core/
│   │   └── config.py        # Settings & environment config
│   ├── routes/
│   │   └── conversation.py  # API endpoints
│   ├── services/
│   │   ├── fluency_analyzer.py      # Filler/hesitation detection
│   │   ├── grammar_corrector.py     # Grammar & word usage fixes
│   │   ├── llm_service.py           # OpenAI/mock responses
│   │   ├── word_assistant.py        # Suggestions & completions
│   │   └── response_formatter.py    # Structured output formatting
│   ├── schemas/
│   │   └── conversation.py  # Pydantic request/response models
│   └── utils/
│       ├── logger.py        # CSV logging
│       └── helpers.py       # Utility functions
├── requirements.txt
└── README.md
```

### Core Modules

**Fluency Analyzer** (`fluency_analyzer.py`)
- Detects filler words (um, uh, like, etc.)
- Identifies repeated words
- Detects hesitation patterns
- Calculates fluency score (0-100)

**Grammar Corrector** (`grammar_corrector.py`)
- Fixes tense issues
- Fixes modal verb forms
- Corrects subject-verb agreement
- Suggests word usage improvements

**LLM Service** (`llm_service.py`)
- Generates natural conversational responses
- Uses OpenAI API (or mock responses for development)
- Generates follow-up questions

**Word Assistant** (`word_assistant.py`)
- Suggests synonyms
- Recommends phrase improvements
- Provides sentence completions

**Response Formatter** (`response_formatter.py`)
- Structures all analysis into clean JSON
- Generates personalized improvement tips
- Formats fluency feedback

**Logger** (`logger.py`)
- Logs all analyses to CSV file (`logs/fluency_analysis.csv`)
- Records: timestamp, user_id, session_id, user_text, corrected_text, fluency_score, filler_count, hesitation_score, filler_density, response_time

**Progress Service** (`progress_service.py`)
- Stores conversation history and progress snapshots in SQLite
- Computes average fluency, common errors, and trend signals

**Memory Service** (`memory_service.py`)
- Keeps a bounded per-session chat memory for LLM context

**Audio Service** (`audio_service.py`)
- Handles audio transcription and text-to-speech output

---

## 🔧 Configuration

Environment variables (`.env`):

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | (empty) | OpenAI API key for real responses |
| `USE_MOCK_LLM` | True | Use mock responses if API key unavailable |
| `DEBUG` | False | Enable debug mode |
| `LOG_FILE` | `logs/fluency_analysis.csv` | Path to logging CSV |

---

## 📊 Logging

All conversation analyses are logged to `logs/fluency_analysis.csv`:

```csv
timestamp,user_text,corrected_text,fluency_score,filler_count,response_time_ms,filler_words
2024-01-15T10:30:45.123Z,"I like um the movie","I like the movie",82.0,1,245.3,"um"
```

Access logs for:
- Research & analysis
- User progress tracking
- System improvement

---

## 🚀 Deployment

### Docker (Optional)

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Run:
```bash
docker build -t fluentflow-backend .
docker run -p 8000:8000 -e OPENAI_API_KEY=your_key fluentflow-backend
```

### Production Notes

1. **Set specific CORS origins** (not `["*"]`)
2. **Use environment-based config** (separate dev/prod settings)
3. **Add authentication** (JWT tokens for frontend)
4. **Enable rate limiting** (prevent abuse)
5. **Monitor logging** (track errors & performance)
6. **Use PostgreSQL** instead of CSV for scaling

---

## 🧪 Testing

Example curl requests:

### Health Check
```bash
curl http://localhost:8000/api/health
```

### Conversation
```bash
curl -X POST http://localhost:8000/api/conversation \
  -H "Content-Type: application/json" \
  -d '{
    "user_text": "I like um the food",
    "conversation_history": []
  }'
```

### Analyze
```bash
curl -X POST http://localhost:8000/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "user_text": "I like um the food"
  }'
```

---

## 📝 Key Features

✅ **Fluency Analysis** - Filler detection, hesitation patterns, scoring  
✅ **Grammar Correction** - Smart tense & agreement fixes  
✅ **AI Responses** - Natural, conversational replies via LLM  
✅ **Word Assistance** - Synonyms, phrase improvements, completions  
✅ **Structured Output** - Clean JSON for frontend integration  
✅ **Comprehensive Logging** - CSV export for research & metrics  
✅ **Mock Mode** - Works without API key for development  
✅ **Clean Architecture** - Modular, testable, scalable  

---

## 🎯 Next Steps

1. **Connect to Frontend** - Integrate with Flutter app
2. **Add Authentication** - JWT tokens for user sessions
3. **Database Integration** - Store chat history & user progress
4. **Enhanced Grammar** - Use language-tool-python for advanced NLP
5. **Speech-to-Text** - Accept audio files (Google Speech API)
6. **Metrics Dashboard** - Track user fluency progress

---

## 📞 Support

For issues or questions, check:
- API docs at `http://localhost:8000/docs`
- Logs in `logs/fluency_analysis.csv`
- Console output for startup messages

---

Built with ❤️ for English learners everywhere
