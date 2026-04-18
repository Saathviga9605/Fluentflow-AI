"""Logging utilities."""

import csv
import os
from datetime import datetime
from app.core.config import settings


class CSVLogger:
    """Logs fluency analysis to CSV file."""

    def __init__(self):
        self.log_dir = settings.log_dir
        self.log_file = settings.log_file
        self._ensure_log_directory()
        self._initialize_csv()

    def _ensure_log_directory(self):
        """Create log directory if it doesn't exist."""
        os.makedirs(self.log_dir, exist_ok=True)

    def _initialize_csv(self):
        """Initialize CSV with headers if it doesn't exist."""
        if not os.path.exists(self.log_file):
            with open(self.log_file, mode="w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow([
                    "timestamp",
                    "user_id",
                    "session_id",
                    "user_text",
                    "corrected_text",
                    "fluency_score",
                    "filler_count",
                    "hesitation_score",
                    "filler_density",
                    "response_time_ms",
                    "filler_words"
                ])

    def log_analysis(
        self,
        user_text: str,
        corrected_text: str,
        fluency_score: float,
        filler_count: int,
        response_time_ms: float,
        filler_words: list,
        user_id: str = "anonymous",
        session_id: str | None = None,
        hesitation_score: float = 0.0,
        filler_density: float = 0.0
    ):
        """Log analysis result to CSV."""
        try:
            with open(self.log_file, mode="a", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow([
                    datetime.utcnow().isoformat(),
                    user_id,
                    session_id or "",
                    user_text,
                    corrected_text,
                    fluency_score,
                    filler_count,
                    hesitation_score,
                    filler_density,
                    response_time_ms,
                    ";".join(filler_words)  # Semicolon-separated list
                ])
        except Exception as e:
            print(f"Error logging to CSV: {e}")

    def log_conversation(
        self,
        user_text: str,
        corrected_text: str,
        ai_response: str,
        fluency_score: float,
        response_time_ms: float,
        filler_count: int = 0,
        user_id: str = "anonymous",
        session_id: str | None = None,
        hesitation_score: float = 0.0,
        filler_density: float = 0.0
    ):
        """Log full conversation to CSV."""
        try:
            with open(self.log_file, mode="a", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow([
                    datetime.utcnow().isoformat(),
                    user_id,
                    session_id or "",
                    user_text,
                    corrected_text,
                    fluency_score,
                    filler_count,
                    hesitation_score,
                    filler_density,
                    response_time_ms,
                    ai_response[:50]  # First 50 chars of response
                ])
        except Exception as e:
            print(f"Error logging conversation: {e}")


# Global logger instance
logger = CSVLogger()
