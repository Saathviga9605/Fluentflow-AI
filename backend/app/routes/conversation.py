"""Conversation routes."""

import time
from fastapi import APIRouter, HTTPException
from app.schemas.conversation import (
    ConversationRequest,
    ConversationResponse,
    AnalyzeRequest,
    AnalyzeResponse,
    HealthResponse,
    FluencyFeedback,
    SuggestionItem
)
from app.services.fluency_analyzer import analyze_fluency
from app.services.grammar_corrector import correct_grammar
from app.services.llm_service import LLMService
from app.services.memory_service import memory_service
from app.services.progress_service import progress_service
from app.services.word_assistant import get_word_assistance
from app.services.response_formatter import (
    format_conversation_response,
    format_analyze_response
)
from app.utils.logger import logger
from app.utils.helpers import clean_text
from app.core.config import settings


router = APIRouter()
llm_service = LLMService()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        version=settings.app_version
    )


@router.post("/conversation", response_model=ConversationResponse)
async def conversation(request: ConversationRequest):
    """
    Full conversation endpoint.

    Analyzes user speech, generates correction, AI response, and feedback.
    """
    try:
        start_time = time.time()

        # Clean input
        user_text = clean_text(request.user_text)

        if not user_text:
            raise HTTPException(status_code=400, detail="User text cannot be empty")

        session_history = memory_service.build_context(
            user_id=request.user_id,
            session_id=request.session_id,
            conversation_history=[item.model_dump() for item in request.conversation_history or []]
        )

        # 1. Fluency Analysis
        fluency_result = analyze_fluency(user_text)

        # 2. Grammar Correction
        corrected_text, correction_explanation = correct_grammar(user_text)

        # 2b. Optional LLM refinement for more natural phrasing.
        # Keep the heuristic correction when running in mock mode so the fallback
        # stays conservative and does not over-edit user intent.
        if not llm_service.use_mock:
            llm_corrected_text = await llm_service.generate_correction(user_text)
            if llm_corrected_text:
                corrected_text = llm_corrected_text

        # 3. LLM Response (conversational reply)
        ai_response = await llm_service.generate_response(
            user_text=user_text,
            corrected_text=corrected_text,
            conversation_history=session_history,
            difficulty_level=request.difficulty_level,
            safe_mode=request.safe_mode,
            language_preference=request.language_preference,
        )

        # 4. Follow-up Question
        follow_up_question = await llm_service.generate_follow_up_question(
            user_text=user_text,
            response=ai_response,
            difficulty_level=request.difficulty_level,
            safe_mode=request.safe_mode,
            language_preference=request.language_preference,
        )

        # 5. Word Assistance
        word_suggestions = get_word_assistance(text=user_text)
        suggestions = [
            SuggestionItem(
                type=s["type"],
                suggestion=s["suggestion"],
                explanation=s.get("explanation")
            )
            for s in word_suggestions
        ]

        # Calculate response time
        response_time_ms = (time.time() - start_time) * 1000

        # 6. Format Response
        response = format_conversation_response(
            original_text=user_text,
            corrected_text=corrected_text,
            ai_response=ai_response,
            follow_up_question=follow_up_question,
            analysis_result=fluency_result,
            word_suggestions=[s.model_dump() for s in suggestions],
            response_time_ms=response_time_ms
        )

        memory_service.add_message(request.user_id, request.session_id, "user", user_text)
        memory_service.add_message(request.user_id, request.session_id, "assistant", ai_response)

        # 7. Log to CSV
        logger.log_conversation(
            user_text=user_text,
            corrected_text=corrected_text,
            ai_response=ai_response,
            fluency_score=fluency_result["fluency_score"],
            response_time_ms=response_time_ms,
            filler_count=fluency_result["filler_count"],
            user_id=request.user_id,
            session_id=request.session_id
        )

        progress_service.record_conversation(
            user_id=request.user_id,
            session_id=request.session_id,
            user_text=user_text,
            corrected_text=corrected_text,
            response=ai_response,
            fluency_score=fluency_result["fluency_score"],
            filler_count=fluency_result["filler_count"],
            response_time_ms=response_time_ms,
            fluency_feedback={
                "filler_words": fluency_result["filler_words"],
                "filler_count": fluency_result["filler_count"],
                "fluency_score": fluency_result["fluency_score"],
                "hesitation_patterns": fluency_result["hesitation_patterns"],
                "repeated_words": fluency_result.get("repeated_words", []),
                "flagged_words": fluency_result.get("flagged_words", []),
            },
            suggestions=[s.model_dump() for s in suggestions]
        )

        # Build Pydantic response
        return ConversationResponse(
            original_text=response["original_text"],
            corrected_text=response["corrected_text"],
            response=response["response"],
            follow_up_question=response.get("follow_up_question"),
            fluency_feedback=FluencyFeedback(
                filler_words=fluency_result["filler_words"],
                filler_count=fluency_result["filler_count"],
                fluency_score=fluency_result["fluency_score"],
                hesitation_patterns=fluency_result["hesitation_patterns"],
                grammar_issues=fluency_result.get("repeated_words", []),
                flagged_words=fluency_result.get("flagged_words", []),
                hesitation_score=fluency_result.get("hesitation_score", 0.0),
                filler_density=fluency_result.get("filler_density", 0.0),
                sentence_breaks=fluency_result.get("sentence_breaks", 0),
                speaking_length_words=fluency_result.get("speaking_length_words", fluency_result.get("word_count", 0)),
                speaking_length_seconds=fluency_result.get("speaking_length_seconds")
            ),
            tips=response["tips"],
            suggestions=suggestions,
            response_time_ms=response["response_time_ms"],
            user_id=request.user_id,
            session_id=request.session_id
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in conversation endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(request: AnalyzeRequest):
    """
    Analyze-only endpoint (no AI response).

    Returns fluency analysis and suggestions only.
    """
    try:
        # Clean input
        user_text = clean_text(request.user_text)

        if not user_text:
            raise HTTPException(status_code=400, detail="User text cannot be empty")

        # 1. Fluency Analysis
        fluency_result = analyze_fluency(user_text)

        # 2. Word Assistance
        word_suggestions = get_word_assistance(text=user_text)
        suggestions = [
            SuggestionItem(
                type=s["type"],
                suggestion=s["suggestion"],
                explanation=s.get("explanation")
            )
            for s in word_suggestions
        ]

        # 3. Format Response
        response = format_analyze_response(
            original_text=user_text,
            analysis_result=fluency_result,
            word_suggestions=[s.model_dump() for s in suggestions]
        )

        # 4. Log
        logger.log_analysis(
            user_text=user_text,
            corrected_text="",
            fluency_score=fluency_result["fluency_score"],
            filler_count=fluency_result["filler_count"],
            response_time_ms=0,
            filler_words=fluency_result["filler_words"],
            user_id=request.user_id,
            session_id=request.session_id,
            hesitation_score=fluency_result.get("hesitation_score", 0.0),
            filler_density=fluency_result.get("filler_density", 0.0)
        )

        return AnalyzeResponse(
            original_text=response["original_text"],
            fluency_feedback=FluencyFeedback(
                filler_words=fluency_result["filler_words"],
                filler_count=fluency_result["filler_count"],
                fluency_score=fluency_result["fluency_score"],
                hesitation_patterns=fluency_result["hesitation_patterns"],
                grammar_issues=fluency_result.get("repeated_words", []),
                flagged_words=fluency_result.get("flagged_words", []),
                hesitation_score=fluency_result.get("hesitation_score", 0.0),
                filler_density=fluency_result.get("filler_density", 0.0),
                sentence_breaks=fluency_result.get("sentence_breaks", 0),
                speaking_length_words=fluency_result.get("speaking_length_words", 0),
                speaking_length_seconds=fluency_result.get("speaking_length_seconds")
            ),
            suggestions=suggestions,
            user_id=request.user_id,
            session_id=request.session_id
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in analyze endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))
