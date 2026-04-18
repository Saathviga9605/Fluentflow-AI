"""LLM service for generating conversational responses."""

from typing import Dict, List, Optional

from app.core.config import settings


# Mock responses for development/demo
MOCK_RESPONSES = [
    "That's great! I love your enthusiasm. Could you tell me more about that?",
    "Excellent point! That's a very natural way to express that idea.",
    "I see what you mean. Have you considered looking at it from this angle?",
    "That's really interesting! How did that make you feel?",
    "Perfect! You're doing really well. What happened next?",
]

MOCK_CORRECTIONS = [
    "That's a great way to put it!",
    "Exactly! You've expressed that perfectly.",
    "Your phrasing is spot-on.",
    "That sounds very natural.",
]


class LLMService:
    """Service for generating responses via LLM."""

    def __init__(self):
        self.api_key = settings.openrouter_api_key or settings.openai_api_key
        self.model = settings.openrouter_model or settings.openai_model
        self.use_mock = settings.use_mock_llm or not self.api_key
        self._client = None

    def _get_client(self):
        if self._client is not None:
            return self._client

        from openai import AsyncOpenAI

        client_kwargs: Dict[str, str] = {"api_key": self.api_key}
        if settings.openrouter_api_key:
            client_kwargs["base_url"] = settings.openrouter_base_url

        self._client = AsyncOpenAI(**client_kwargs)
        return self._client

    async def _chat_completion(
        self,
        *,
        messages: List[Dict],
        temperature: float,
        max_tokens: int,
    ) -> str:
        client = self._get_client()

        request_kwargs: Dict[str, object] = {}
        if settings.openrouter_api_key:
            request_kwargs["extra_headers"] = {
                "HTTP-Referer": settings.openrouter_site_url,
                "X-Title": settings.openrouter_app_name,
            }

        completion = await client.chat.completions.create(
            model=self.model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            **request_kwargs,
        )
        content = completion.choices[0].message.content
        return (content or "").strip()

    async def generate_response(
        self,
        user_text: str,
        corrected_text: str,
        conversation_history: Optional[List[Dict]] = None,
        difficulty_level: float = 0.4,
        safe_mode: bool = True,
        language_preference: str = "English only",
    ) -> str:
        """
        Generate natural conversational response.

        Args:
            user_text: Original user text
            corrected_text: Corrected version
            conversation_history: Previous messages

        Returns:
            Natural conversational response
        """
        if self.use_mock:
            return self._get_mock_response()

        try:
            messages = self._build_messages(
                user_text,
                corrected_text,
                conversation_history,
                difficulty_level=difficulty_level,
                safe_mode=safe_mode,
                language_preference=language_preference,
            )

            return await self._chat_completion(
                messages=messages,
                temperature=0.7,
                max_tokens=150,
            )
        except Exception as e:
            print(f"LLM error: {e}, falling back to mock response")
            return self._get_mock_response()

    async def generate_correction(self, user_text: str) -> str:
        """
        Generate a more natural corrected sentence.

        This keeps the correction layer reusable even when the app is running
        in mock mode.
        """
        if self.use_mock:
            return self._mock_correct_sentence(user_text)

        try:
            prompt = f"""
Rewrite the following user sentence so it sounds natural, fluent, and conversational.
Keep the meaning the same. Do not over-correct. Return only the corrected sentence.

User sentence: {user_text}
"""

            return await self._chat_completion(
                messages=[
                    {"role": "system", "content": "You improve English fluency without sounding robotic."},
                    {"role": "user", "content": prompt},
                ],
                temperature=0.3,
                max_tokens=80,
            )
        except Exception as e:
            print(f"Correction generation error: {e}, falling back to mock correction")
            return self._mock_correct_sentence(user_text)

    async def generate_follow_up_question(
        self,
        user_text: str,
        response: str,
        difficulty_level: float = 0.4,
        safe_mode: bool = True,
        language_preference: str = "English only",
    ) -> Optional[str]:
        """
        Generate natural follow-up question.

        Args:
            user_text: User's text
            response: Our response

        Returns:
            Follow-up question or None
        """
        if self.use_mock:
            return "Could you elaborate on that?"

        try:
            prompt = f"""
Based on this conversation:
User: {user_text}
Assistant: {response}

Conversation settings:
- Difficulty level: {difficulty_level:.2f} (0 gentle to 1 challenging)
- Safe mode: {safe_mode}
- Language preference: {language_preference}

Generate a natural follow-up question to continue the conversation.
Question only, no explanation.
            """

            return await self._chat_completion(
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                max_tokens=50,
            )
        except Exception as e:
            print(f"Follow-up question generation error: {e}")
            return None

    def _build_messages(
        self,
        user_text: str,
        corrected_text: str,
        conversation_history: Optional[List[Dict]] = None,
        difficulty_level: float = 0.4,
        safe_mode: bool = True,
        language_preference: str = "English only",
    ) -> List[Dict]:
        """Build message history for API call."""
        difficulty_style = "gentle"
        if difficulty_level >= 0.75:
            difficulty_style = "challenging"
        elif difficulty_level >= 0.5:
            difficulty_style = "balanced"

        safe_mode_instruction = (
            "Use extra-soft, reassuring wording and avoid harsh critique."
            if safe_mode
            else "Use direct but respectful coaching and push for stronger phrasing."
        )

        language_instruction = (
            "Prioritize English. If helpful, add brief bilingual hints with simple Tamil context cues."
            if language_preference.lower().startswith("tamil")
            else "Respond in natural English only."
        )

        messages = [
            {
                "role": "system",
                "content": f"""You are a friendly English conversation partner helping someone improve their fluency.
Your role is to:
1. Continue the conversation naturally
2. Be encouraging and supportive
3. Ask follow-up questions to keep conversation flowing
4. Never be condescending or overly formal
5. Sound like a real human, not a language teacher

Coaching style:
- Difficulty mode: {difficulty_style}
- {safe_mode_instruction}
- {language_instruction}

Keep responses concise (1-2 sentences usually) and natural."""
            }
        ]

        # Add conversation history
        if conversation_history:
            for item in conversation_history:
                messages.append({
                    "role": item.get("role", "user"),
                    "content": item.get("content", "")
                })

        # Add current user message (use corrected version for better context)
        messages.append({
            "role": "user",
            "content": corrected_text or user_text
        })

        return messages

    @staticmethod
    def _get_mock_response() -> str:
        """Get a random mock response for demo."""
        import random
        return random.choice(MOCK_RESPONSES)

    @staticmethod
    def _mock_correct_sentence(user_text: str) -> str:
        """Lightweight fallback correction for demo mode."""
        import re

        text = user_text.strip()
        replacements = {
            r"\bum\b": "",
            r"\buh\b": "",
            r"\blike\b": "",
            r"\byou know\b": "",
            r"\s+": " ",
        }

        for pattern, replacement in replacements.items():
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        text = text.strip(" ,")

        if not text:
            return user_text.strip()

        if text[-1] not in ".?!":
            text += "."

        return text

    @staticmethod
    def _get_mock_correction_feedback() -> str:
        """Get mock correction feedback."""
        import random
        return random.choice(MOCK_CORRECTIONS)
