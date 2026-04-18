"""SQLite-backed progress tracking and history storage."""

from __future__ import annotations

import json
import os
import sqlite3
from datetime import datetime
from threading import Lock
from typing import Any, Dict, List, Optional

from app.core.config import settings


class ProgressService:
    """Store conversation history and derive user progress metrics."""

    def __init__(self) -> None:
        self.db_path = settings.sqlite_db_path
        self._lock = Lock()
        self._ensure_database()

    def _ensure_database(self) -> None:
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        with sqlite3.connect(self.db_path) as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS conversations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    session_id TEXT,
                    role TEXT NOT NULL DEFAULT 'user',
                    user_text TEXT NOT NULL,
                    corrected_text TEXT,
                    response TEXT,
                    fluency_score REAL,
                    filler_count INTEGER,
                    response_time_ms REAL,
                    fluency_feedback_json TEXT,
                    suggestions_json TEXT,
                    created_at TEXT NOT NULL
                )
                """
            )
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS progress_summary (
                    user_id TEXT PRIMARY KEY,
                    total_conversations INTEGER NOT NULL DEFAULT 0,
                    scores_json TEXT NOT NULL DEFAULT '[]',
                    filler_history_json TEXT NOT NULL DEFAULT '[]',
                    error_counts_json TEXT NOT NULL DEFAULT '{}',
                    updated_at TEXT NOT NULL
                )
                """
            )
            connection.commit()

    def record_conversation(
        self,
        user_id: str,
        session_id: Optional[str],
        user_text: str,
        corrected_text: str,
        response: str,
        fluency_score: float,
        filler_count: int,
        response_time_ms: float,
        fluency_feedback: Dict[str, Any],
        suggestions: List[Dict[str, Any]]
    ) -> None:
        """Persist a completed conversation and update aggregate progress."""
        timestamp = datetime.utcnow().isoformat()
        with self._lock, sqlite3.connect(self.db_path) as connection:
            connection.execute(
                """
                INSERT INTO conversations (
                    user_id, session_id, role, user_text, corrected_text, response,
                    fluency_score, filler_count, response_time_ms, fluency_feedback_json,
                    suggestions_json, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    user_id,
                    session_id,
                    "user",
                    user_text,
                    corrected_text,
                    response,
                    fluency_score,
                    filler_count,
                    response_time_ms,
                    json.dumps(fluency_feedback),
                    json.dumps(suggestions),
                    timestamp,
                ),
            )

            progress = self._get_progress_row(connection, user_id)
            scores = json.loads(progress["scores_json"])
            filler_history = json.loads(progress["filler_history_json"])
            error_counts = json.loads(progress["error_counts_json"])

            scores.append(fluency_score)
            filler_history.append(filler_count)

            for label in self._extract_error_labels(fluency_feedback):
                error_counts[label] = int(error_counts.get(label, 0)) + 1

            connection.execute(
                """
                INSERT INTO progress_summary (
                    user_id, total_conversations, scores_json, filler_history_json,
                    error_counts_json, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(user_id) DO UPDATE SET
                    total_conversations=excluded.total_conversations,
                    scores_json=excluded.scores_json,
                    filler_history_json=excluded.filler_history_json,
                    error_counts_json=excluded.error_counts_json,
                    updated_at=excluded.updated_at
                """,
                (
                    user_id,
                    progress["total_conversations"] + 1,
                    json.dumps(scores),
                    json.dumps(filler_history),
                    json.dumps(error_counts),
                    timestamp,
                ),
            )
            connection.commit()

    def get_progress(self, user_id: str) -> Dict[str, Any]:
        """Return aggregate progress metrics for a user."""
        with sqlite3.connect(self.db_path) as connection:
            connection.row_factory = sqlite3.Row
            progress = self._get_progress_row(connection, user_id)
            history = self.get_history(user_id, limit=settings.history_limit)

        scores = json.loads(progress["scores_json"])
        filler_history = json.loads(progress["filler_history_json"])
        error_counts = json.loads(progress["error_counts_json"])

        average_score = round(sum(scores) / len(scores), 2) if scores else 0.0
        improvement_trend = self._compute_trend(scores)
        filler_trend = self._compute_trend([float(item) for item in filler_history], prefer_lower=True)
        common_errors = [
            {"label": label, "count": count}
            for label, count in sorted(error_counts.items(), key=lambda item: item[1], reverse=True)[:5]
        ]

        return {
            "user_id": user_id,
            "total_conversations": progress["total_conversations"],
            "average_fluency_score": average_score,
            "improvement_trend": improvement_trend,
            "filler_usage_trend": filler_trend,
            "common_errors": common_errors,
            "recent_scores": scores[-10:],
            "latest_activity": history[0]["created_at"] if history else None,
        }

    def get_history(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Return a user's past conversations."""
        with sqlite3.connect(self.db_path) as connection:
            connection.row_factory = sqlite3.Row
            rows = connection.execute(
                """
                SELECT id, user_id, session_id, user_text, corrected_text, response,
                       fluency_score, filler_count, response_time_ms, created_at
                FROM conversations
                WHERE user_id = ?
                ORDER BY id DESC
                LIMIT ?
                """,
                (user_id, limit),
            ).fetchall()

        return [dict(row) for row in rows]

    def _get_progress_row(self, connection: sqlite3.Connection, user_id: str) -> Dict[str, Any]:
        connection.row_factory = sqlite3.Row
        row = connection.execute(
            """
            SELECT user_id, total_conversations, scores_json, filler_history_json, error_counts_json, updated_at
            FROM progress_summary
            WHERE user_id = ?
            """,
            (user_id,),
        ).fetchone()

        if row is None:
            return {
                "user_id": user_id,
                "total_conversations": 0,
                "scores_json": "[]",
                "filler_history_json": "[]",
                "error_counts_json": "{}",
                "updated_at": None,
            }

        return row

    @staticmethod
    def _extract_error_labels(fluency_feedback: Dict[str, Any]) -> List[str]:
        labels: List[str] = []
        for filler in fluency_feedback.get("filler_words", []):
            labels.append(f"filler:{filler}")
        for hesitation in fluency_feedback.get("hesitation_patterns", []):
            labels.append(f"hesitation:{hesitation}")
        for issue in fluency_feedback.get("repeated_words", []) or fluency_feedback.get("grammar_issues", []):
            labels.append(f"repetition:{issue}")
        return labels

    @staticmethod
    def _compute_trend(values: List[float], prefer_lower: bool = False) -> Dict[str, Any]:
        if not values:
            return {"direction": "flat", "delta": 0.0, "label": "No data yet"}

        if len(values) == 1:
            return {"direction": "flat", "delta": 0.0, "label": "Only one data point"}

        midpoint = max(1, len(values) // 2)
        first_half = values[:midpoint]
        second_half = values[midpoint:]
        first_avg = sum(first_half) / len(first_half)
        second_avg = sum(second_half) / len(second_half)
        delta = round(second_avg - first_avg, 2)

        if abs(delta) < 0.1:
            direction = "flat"
        else:
            direction = "down" if (prefer_lower and delta < 0) or (not prefer_lower and delta < 0) else "up"

        if prefer_lower:
            label = "Improving" if delta < 0 else "Needs attention" if delta > 0 else "Stable"
        else:
            label = "Improving" if delta > 0 else "Needs attention" if delta < 0 else "Stable"

        return {"direction": direction, "delta": delta, "label": label}


progress_service = ProgressService()
