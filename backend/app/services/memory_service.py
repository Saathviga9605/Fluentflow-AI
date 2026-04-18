"""Session-based conversation memory."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, asdict
from threading import Lock
from typing import Deque, Dict, List

from app.core.config import settings


@dataclass
class MemoryMessage:
    """Single memory entry used for LLM context."""

    role: str
    content: str


class ConversationMemoryService:
    """Keep a short per-session conversation window in memory."""

    def __init__(self) -> None:
        self._store: Dict[str, Deque[MemoryMessage]] = {}
        self._lock = Lock()

    def _session_key(self, user_id: str, session_id: str | None) -> str:
        return f"{user_id}:{session_id or 'default'}"

    def get_history(self, user_id: str, session_id: str | None = None) -> List[Dict[str, str]]:
        """Return the stored history for a session as a list of dictionaries."""
        key = self._session_key(user_id, session_id)
        with self._lock:
            entries = list(self._store.get(key, deque()))
        return [asdict(item) for item in entries]

    def seed_history(
        self,
        user_id: str,
        session_id: str | None,
        history: List[Dict[str, str]]
    ) -> None:
        """Seed the memory with history from the frontend when available."""
        if not history:
            return

        key = self._session_key(user_id, session_id)
        with self._lock:
            bucket = self._store.setdefault(key, deque(maxlen=settings.max_memory_messages))
            for item in history[-settings.max_memory_messages:]:
                role = item.get("role", "user")
                content = item.get("content", "")
                if content:
                    bucket.append(MemoryMessage(role=role, content=content))

    def add_message(self, user_id: str, session_id: str | None, role: str, content: str) -> None:
        """Add a message to the active memory window."""
        if not content:
            return

        key = self._session_key(user_id, session_id)
        with self._lock:
            bucket = self._store.setdefault(key, deque(maxlen=settings.max_memory_messages))
            bucket.append(MemoryMessage(role=role, content=content))

    def build_context(
        self,
        user_id: str,
        session_id: str | None,
        conversation_history: List[Dict[str, str]] | None = None
    ) -> List[Dict[str, str]]:
        """Combine stored memory with the current request context."""
        combined = self.get_history(user_id, session_id)
        if conversation_history:
            combined.extend(conversation_history)
        return combined[-settings.max_memory_messages :]

    def clear_session(self, user_id: str, session_id: str | None = None) -> None:
        """Remove a session from memory."""
        key = self._session_key(user_id, session_id)
        with self._lock:
            self._store.pop(key, None)


memory_service = ConversationMemoryService()
