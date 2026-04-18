"""Media routes for speech processing."""

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from app.services.audio_service import audio_service, TranscriptionResult


router = APIRouter()


class TextToSpeechRequest(BaseModel):
    """Request body for text-to-speech."""

    text: str = Field(..., min_length=1, description="Text to convert to speech")


class SpeechToTextResponse(BaseModel):
    """Response body for speech-to-text."""

    text: str
    backend: str
    language: str = "en"
    duration_seconds: float | None = None


@router.post("/speech-to-text", response_model=SpeechToTextResponse)
async def speech_to_text(audio_file: UploadFile = File(...)):
    """Transcribe an uploaded audio clip into text."""
    try:
        result: TranscriptionResult = await audio_service.transcribe_upload(audio_file)
        if not result.text:
            raise HTTPException(status_code=422, detail="No speech detected in the uploaded audio")
        return SpeechToTextResponse(
            text=result.text,
            backend=result.backend,
            language=result.language,
            duration_seconds=result.duration_seconds,
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Speech-to-text failed: {exc}") from exc


@router.post("/text-to-speech")
async def text_to_speech(request: TextToSpeechRequest):
    """Convert text into an audio stream."""
    try:
        response = audio_service.synthesize_text(request.text)
        if not isinstance(response, StreamingResponse):
            raise HTTPException(status_code=500, detail="Unexpected audio response")
        return response
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Text-to-speech failed: {exc}") from exc
