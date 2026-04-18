"""Schemas for analytics, progress tracking, and conversation history."""

from __future__ import annotations

from typing import Any, List, Optional

from pydantic import BaseModel, Field


class ProgressResponse(BaseModel):
    """Progress summary for a user."""

    user_id: str
    total_conversations: int
    average_fluency_score: float
    improvement_trend: dict[str, Any]
    filler_usage_trend: dict[str, Any]
    common_errors: List[dict[str, Any]] = Field(default_factory=list)
    recent_scores: List[float] = Field(default_factory=list)
    latest_activity: Optional[str] = None


class ConversationHistoryItem(BaseModel):
    """Single conversation record from history."""

    id: int
    user_id: str
    session_id: Optional[str] = None
    user_text: str
    corrected_text: Optional[str] = None
    response: Optional[str] = None
    fluency_score: Optional[float] = None
    filler_count: Optional[int] = None
    response_time_ms: Optional[float] = None
    created_at: str


class HistoryResponse(BaseModel):
    """Conversation history payload."""

    user_id: str
    conversations: List[ConversationHistoryItem] = Field(default_factory=list)
