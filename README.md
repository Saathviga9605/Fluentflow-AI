# SPEAKEASY

SPEAKEASY is a full-stack English fluency assistant with:
- A Flutter client app in `app/`
- A FastAPI backend in `backend/`
- Local runtime data and logs in `data/`

The system supports conversation coaching, fluency analysis, speech workflows, and progress tracking.

## Project Structure

```
SPEAKEASY/
├── app/                  # Flutter mobile/web/desktop client
├── backend/              # FastAPI service and AI logic
├── data/                 # Runtime data (SQLite, logs, exports)
└── README.md             # Project-level guide
```

## Tech Stack

### Frontend (`app/`)
- Flutter (Dart)
- Provider for state management
- Firebase (auth-ready integration)
- HTTP client for backend communication
- Speech-to-text and text-to-speech packages

### Backend (`backend/`)
- FastAPI + Uvicorn
- Pydantic + pydantic-settings
- OpenAI/OpenRouter capable LLM integration (with mock fallback)
- CSV + SQLite logging/storage
- Audio endpoints for STT/TTS workflows

## Prerequisites

Install these before running locally:
- Flutter SDK (stable)
- Python 3.9+
- pip
- Git

Optional but recommended:
- Android Studio/Xcode (for mobile targets)
- VS Code Flutter and Python extensions

## Quick Start

Run the backend and app in separate terminals.

### 1) Start Backend

From workspace root:

```bash
cd backend
python -m venv venv
# Windows
venv\Scripts\activate
# macOS/Linux
# source venv/bin/activate

pip install -r requirements.txt
python main.py
```

Backend default URL: `http://localhost:8000`
API docs:
- `http://localhost:8000/docs`
- `http://localhost:8000/redoc`

### 2) Configure Backend Environment (optional but recommended)

Create `backend/.env` for local overrides:

```env
DEBUG=true
RELOAD=true
USE_MOCK_LLM=true
OPENAI_API_KEY=
OPENROUTER_API_KEY=
PORT=8000
```

Notes:
- If API keys are empty, keep mock mode enabled for local development.
- `RELOAD=true` enables auto-reload while coding.

### 3) Start Flutter App

From workspace root:

```bash
cd app
flutter pub get
flutter run
```

If you target web:

```bash
flutter run -d chrome
```

## Core Runtime Flow

1. User interacts with the Flutter app.
2. App sends requests to FastAPI endpoints.
3. Backend runs fluency analysis and response generation.
4. Backend returns corrections, suggestions, and follow-ups.
5. Analytics/history data is written to local logs/storage.

## Main Backend Endpoints

- `GET /health` - service health
- `POST /conversation` - full conversation processing
- `POST /analyze` - analysis-focused endpoint
- `POST /speech-to-text` - audio to text
- `POST /text-to-speech` - text to audio
- `GET /progress/{user_id}` - user progress summary
- `GET /history/{user_id}` - conversation history

## Development Notes

- Backend entry point: `backend/main.py`
- App entry point: `app/lib/main.dart`
- Keep generated folders (`build/`, platform intermediates) out of manual edits.
- Use mock LLM mode during offline/local testing.

## Troubleshooting

### Backend does not start
- Confirm virtual environment is active.
- Reinstall dependencies: `pip install -r backend/requirements.txt`
- Check for port conflicts on `8000`.

### Flutter build issues
- Run `flutter clean` then `flutter pub get`.
- Verify Flutter SDK and platform toolchains are installed.

### No AI responses
- Ensure `USE_MOCK_LLM=true` for local testing without API keys.
- If using real APIs, set valid `OPENAI_API_KEY` or `OPENROUTER_API_KEY` in `backend/.env`.

## Folder-Specific Docs

- App details: `app/README.md`
- Backend details: `backend/README.md`
