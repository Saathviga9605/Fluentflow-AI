from typing import Optional, List
from pydantic import BaseModel, Field


class ConversationHistoryItem(BaseModel):
    """Represents a single message in conversation history."""
    role: str = Field(..., description="'user' or 'assistant'")
    content: str = Field(..., description="Message content")


class FluencyFeedback(BaseModel):
    """Fluency analysis feedback."""
    filler_words: List[str] = Field(default_factory=list, description="Detected filler words")
    filler_count: int = Field(default=0, description="Number of filler words detected")
    fluency_score: float = Field(default=100.0, description="Fluency score 0-100")
    hesitation_patterns: List[str] = Field(default_factory=list, description="Detected hesitation patterns")
    grammar_issues: List[str] = Field(default_factory=list, description="Detected grammar issues")
    flagged_words: List[str] = Field(default_factory=list, description="Words flagged by the fluency analyzer")
    hesitation_score: float = Field(default=0.0, description="Normalized hesitation score 0-100")
    filler_density: float = Field(default=0.0, description="Share of filler words in the utterance")
    sentence_breaks: int = Field(default=0, description="Sentence break markers detected")
    speaking_length_words: int = Field(default=0, description="Approximate speaking length in words")
    speaking_length_seconds: Optional[float] = Field(default=None, description="Estimated speaking length in seconds")


class SuggestionItem(BaseModel):
    """Word assistance suggestion."""
    type: str = Field(..., description="'synonym', 'phrase', 'completion'")
    suggestion: str = Field(..., description="Suggested word or phrase")
    explanation: Optional[str] = Field(default=None, description="Why this suggestion")


class ConversationRequest(BaseModel):
    """Request body for conversation endpoint."""
    user_text: str = Field(..., description="User's spoken/typed text", min_length=1)
    conversation_history: Optional[List[ConversationHistoryItem]] = Field(
        default_factory=list,
        description="Previous messages in conversation"
    )
    user_id: str = Field(default="anonymous", description="Stable user identifier")
    session_id: Optional[str] = Field(default=None, description="Conversation session identifier")
    difficulty_level: float = Field(default=0.4, ge=0.0, le=1.0, description="Coaching difficulty 0-1")
    safe_mode: bool = Field(default=True, description="Gentle supportive coaching toggle")
    language_preference: str = Field(default="English only", description="Preferred speaking support language")


class AnalyzeRequest(BaseModel):
    """Request body for analyze endpoint."""
    user_text: str = Field(..., description="Text to analyze", min_length=1)
    user_id: str = Field(default="anonymous", description="Stable user identifier")
    session_id: Optional[str] = Field(default=None, description="Conversation session identifier")


class ConversationResponse(BaseModel):
    """Full response from conversation endpoint."""
    original_text: str = Field(..., description="Original user text")
    corrected_text: str = Field(..., description="Grammar/usage corrected version")
    response: str = Field(..., description="AI conversational reply")
    follow_up_question: Optional[str] = Field(default=None, description="Natural follow-up question")
    fluency_feedback: FluencyFeedback = Field(..., description="Detailed fluency analysis")
    tips: List[str] = Field(default_factory=list, description="Improvement tips")
    suggestions: List[SuggestionItem] = Field(default_factory=list, description="Word assistance")
    response_time_ms: float = Field(..., description="Time to generate response in milliseconds")
    user_id: str = Field(default="anonymous", description="User identifier")
    session_id: Optional[str] = Field(default=None, description="Conversation session identifier")


class AnalyzeResponse(BaseModel):
    """Response from analyze endpoint."""
    original_text: str = Field(..., description="Original text")
    fluency_feedback: FluencyFeedback = Field(..., description="Fluency analysis")
    suggestions: List[SuggestionItem] = Field(default_factory=list, description="Suggestions")
    user_id: str = Field(default="anonymous", description="User identifier")
    session_id: Optional[str] = Field(default=None, description="Conversation session identifier")


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = Field(default="healthy", description="Service status")
    version: str = Field(..., description="API version")
