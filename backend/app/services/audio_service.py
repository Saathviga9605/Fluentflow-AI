"""Audio processing services for speech-to-text and text-to-speech."""

from __future__ import annotations

import io
import os
import tempfile
import wave
from dataclasses import dataclass
from typing import Optional

from fastapi import HTTPException, UploadFile
from fastapi.responses import StreamingResponse

from app.core.config import settings


@dataclass
class TranscriptionResult:
    """Result returned by the STT pipeline."""

    text: str
    language: str = "en"
    backend: str = "mock"
    duration_seconds: Optional[float] = None


class AudioService:
    """Handle audio transcription and synthesis."""

    def __init__(self) -> None:
        self.whisper_backend = settings.whisper_backend.lower()
        self.use_mock_stt = settings.use_mock_stt
        self.use_mock_tts = settings.use_mock_tts
        self._whisper_model = None

    async def transcribe_upload(self, upload: UploadFile) -> TranscriptionResult:
        """Transcribe an uploaded audio file into text."""
        if self.use_mock_stt:
            return TranscriptionResult(
                text="This is a mock transcription. Install Whisper or faster-whisper for real audio transcription.",
                backend="mock",
                duration_seconds=0.0
            )

        contents = await upload.read()
        if not contents:
            raise HTTPException(status_code=400, detail="Uploaded audio file is empty")

        suffix = self._suffix_for_upload(upload.filename or "audio.wav")
        temp_path = self._write_temp_audio(contents, suffix)
        try:
            if self.whisper_backend == "whisper":
                return self._transcribe_with_whisper(temp_path)
            return self._transcribe_with_faster_whisper(temp_path)
        except ModuleNotFoundError as exc:
            raise HTTPException(
                status_code=503,
                detail=(
                    "Speech transcription is not available because Whisper/faster-whisper "
                    "is not installed in this environment."
                )
            ) from exc
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Speech transcription failed: {exc}") from exc
        finally:
            try:
                os.remove(temp_path)
            except OSError:
                pass

    def synthesize_text(self, text: str) -> StreamingResponse:
        """Convert text into an MP3 audio stream."""
        if not text.strip():
            raise HTTPException(status_code=400, detail="Text cannot be empty")

        if self.use_mock_tts:
            return self._mock_tts_stream(text)

        try:
            from gtts import gTTS
        except ModuleNotFoundError as exc:
            return self._mock_tts_stream(text)

        try:
            buffer = io.BytesIO()
            gTTS(text=text, lang=settings.tts_language).write_to_fp(buffer)
            buffer.seek(0)
            headers = {"Content-Disposition": 'attachment; filename="fluentflow-tts.mp3"'}
            return StreamingResponse(buffer, media_type="audio/mpeg", headers=headers)
        except Exception:
            return self._mock_tts_stream(text)

    def _transcribe_with_whisper(self, path: str) -> TranscriptionResult:
        import whisper

        model = self._load_whisper_model(lambda: whisper.load_model(settings.whisper_model_size))
        result = model.transcribe(path)
        return TranscriptionResult(
            text=result.get("text", "").strip(),
            language=result.get("language", "en"),
            backend="whisper"
        )

    def _transcribe_with_faster_whisper(self, path: str) -> TranscriptionResult:
        from faster_whisper import WhisperModel

        def loader() -> WhisperModel:
            return WhisperModel(settings.whisper_model_size, device="cpu", compute_type="int8")

        model = self._load_whisper_model(loader)
        segments, info = model.transcribe(path, beam_size=1)
        text = " ".join(segment.text.strip() for segment in segments).strip()
        return TranscriptionResult(
            text=text,
            language=getattr(info, "language", "en"),
            backend="faster-whisper"
        )

    def _load_whisper_model(self, loader):
        if self._whisper_model is None:
            self._whisper_model = loader()
        return self._whisper_model

    @staticmethod
    def _write_temp_audio(contents: bytes, suffix: str) -> str:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            temp_file.write(contents)
            return temp_file.name

    @staticmethod
    def _suffix_for_upload(filename: str) -> str:
        _, extension = os.path.splitext(filename)
        return extension if extension else ".wav"

    @staticmethod
    def _mock_tts_stream(text: str) -> StreamingResponse:
        """Return a valid silent WAV stream for development mode."""
        buffer = io.BytesIO()
        with wave.open(buffer, "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(16000)
            wav_file.writeframes(b"\x00\x00" * 16000)

        buffer.seek(0)
        headers = {"Content-Disposition": 'attachment; filename="fluentflow-tts.wav"'}
        return StreamingResponse(buffer, media_type="audio/wav", headers=headers)


audio_service = AudioService()
