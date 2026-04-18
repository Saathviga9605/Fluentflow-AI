"""Response formatting service."""

from typing import List, Dict, Optional
from datetime import datetime


def format_fluency_feedback(analysis_result: dict) -> Dict:
    """
    Format fluency analysis into structured feedback.

    Args:
        analysis_result: Raw fluency analysis from fluency_analyzer

    Returns:
        Structured fluency feedback
    """
    return {
        "filler_words": analysis_result.get("filler_words", []),
        "filler_count": analysis_result.get("filler_count", 0),
        "fluency_score": analysis_result.get("fluency_score", 100.0),
        "hesitation_patterns": analysis_result.get("hesitation_patterns", []),
        "grammar_issues": analysis_result.get("repeated_words", []),
        "flagged_words": analysis_result.get("flagged_words", []),
        "hesitation_score": analysis_result.get("hesitation_score", 0.0),
        "filler_density": analysis_result.get("filler_density", 0.0),
        "sentence_breaks": analysis_result.get("sentence_breaks", 0),
        "speaking_length_words": analysis_result.get("speaking_length_words", analysis_result.get("word_count", 0)),
        "speaking_length_seconds": analysis_result.get("speaking_length_seconds")
    }


def generate_improvement_tips(
    analysis_result: dict,
    grammar_suggestions: Optional[List[Dict]] = None
) -> List[str]:
    """
    Generate personalized improvement tips.

    Args:
        analysis_result: Raw fluency analysis
        grammar_suggestions: Grammar correction suggestions

    Returns:
        List of improvement tips
    """
    tips = []

    # Tip based on fillers
    filler_count = analysis_result.get("filler_count", 0)
    if filler_count > 3:
        tips.append("Try to reduce filler words like 'um' and 'uh' - take a breath instead!")
    elif filler_count > 1:
        tips.append("Good effort! You used a few filler words - practice speaking more confidently.")

    filler_density = analysis_result.get("filler_density", 0.0)
    if filler_density >= 0.15:
        tips.append("Your filler density is high. Slow down slightly and pause before speaking.")

    # Tip based on repeated words
    repeated = analysis_result.get("repeated_words", [])
    if repeated:
        tips.append(f"You repeated '{repeated[0]}' - try using different words to add variety.")

    if analysis_result.get("sentence_breaks", 0) <= 1 and analysis_result.get("word_count", 0) > 8:
        tips.append("Try breaking longer ideas into clearer sentence chunks.")

    # Tip based on hesitation
    hesitations = analysis_result.get("hesitation_patterns", [])
    if hesitations:
        tips.append("Your speech had some hesitation markers - speak with more confidence!")

    # Tip based on sentence completeness
    if not analysis_result.get("is_complete", True):
        tips.append("Try to complete your thoughts with full sentences.")

    # Tip based on word count
    word_count = analysis_result.get("word_count", 0)
    if word_count < 5:
        tips.append("Try saying more - longer utterances help improve fluency!")

    speaking_length = analysis_result.get("speaking_length_seconds")
    if speaking_length and speaking_length > 18:
        tips.append("You spoke for a while. Watch for drifting and keep your main point clear.")

    # General encouragement
    if not tips:
        tips.append("Excellent! You're doing great. Keep practicing!")

    return tips


def format_conversation_response(
    original_text: str,
    corrected_text: str,
    ai_response: str,
    follow_up_question: Optional[str],
    analysis_result: dict,
    word_suggestions: List[Dict],
    response_time_ms: float
) -> Dict:
    """
    Format complete conversation response.

    Args:
        original_text: Original user input
        corrected_text: Grammar-corrected version
        ai_response: AI's conversational response
        follow_up_question: Natural follow-up question
        analysis_result: Fluency analysis result
        word_suggestions: Word assistance suggestions
        response_time_ms: Time to generate response

    Returns:
        Formatted response ready for JSON serialization
    """
    fluency_feedback = format_fluency_feedback(analysis_result)
    tips = generate_improvement_tips(analysis_result)

    return {
        "original_text": original_text,
        "corrected_text": corrected_text,
        "response": ai_response,
        "follow_up_question": follow_up_question,
        "fluency_feedback": fluency_feedback,
        "tips": tips,
        "suggestions": word_suggestions,
        "response_time_ms": response_time_ms,
        "timestamp": datetime.utcnow().isoformat()
    }


def format_analyze_response(
    original_text: str,
    analysis_result: dict,
    word_suggestions: List[Dict]
) -> Dict:
    """
    Format analyze-only response.

    Args:
        original_text: Original user input
        analysis_result: Fluency analysis result
        word_suggestions: Word assistance suggestions

    Returns:
        Formatted analyze response
    """
    fluency_feedback = format_fluency_feedback(analysis_result)
    tips = generate_improvement_tips(analysis_result)

    return {
        "original_text": original_text,
        "fluency_feedback": fluency_feedback,
        "suggestions": word_suggestions,
        "tips": tips,
        "timestamp": datetime.utcnow().isoformat()
    }
