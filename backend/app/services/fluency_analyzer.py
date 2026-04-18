"""Fluency analysis service."""

import re
from typing import List, Tuple

from app.core.config import settings


FILLER_WORDS = set(settings.fluency_fillers + [
    "er", "ah", "actually", "basically", "literally", "honestly",
    "i mean", "sort of", "kind of", "right"
])


def detect_fillers(text: str) -> Tuple[List[str], int]:
    """
    Detect filler words in text.

    Args:
        text: User's text input

    Returns:
        Tuple of (list of detected filler words, count)
    """
    text_lower = text.lower()
    detected = []

    for filler in FILLER_WORDS:
        # Use word boundaries to avoid partial matches
        pattern = r'\b' + re.escape(filler) + r'\b'
        matches = re.findall(pattern, text_lower)
        if matches:
            detected.extend(matches)

    return detected, len(detected)


def detect_repeated_words(text: str) -> List[str]:
    """
    Detect repeated words within a short window.

    Args:
        text: User's text input

    Returns:
        List of repeatedly used words
    """
    words = text.lower().split()
    repeated = []

    for i in range(len(words) - 1):
        if words[i] == words[i + 1] and len(words[i]) > 2:
            if words[i] not in repeated:
                repeated.append(words[i])

    return repeated


def detect_hesitation_patterns(text: str) -> List[str]:
    """
    Detect hesitation patterns like pauses, ellipsis, etc.

    Args:
        text: User's text input

    Returns:
        List of detected hesitation indicators
    """
    patterns = []

    if "..." in text or "…" in text:
        patterns.append("ellipsis_pause")

    if "," in text:
        patterns.append("pause_comma")

    if "--" in text or "-" in text:
        patterns.append("dash_break")

    if text.endswith("?") and len(text.split()) < 3:
        patterns.append("short_question_uncertainty")

    # Multiple question marks
    if text.count("?") > 1:
        patterns.append("multiple_questions")

    return patterns


def count_sentence_breaks(text: str) -> int:
    """Count sentence break markers in the utterance."""
    return text.count(".") + text.count("!") + text.count("?") + text.count("...")


def estimate_speaking_length(word_count: int) -> float:
    """Estimate speaking length in seconds using a rough words-per-minute rate."""
    words_per_minute = 130.0
    return round((word_count / words_per_minute) * 60.0, 2)


def check_sentence_completeness(text: str) -> bool:
    """
    Basic check if sentence appears complete.

    Args:
        text: User's text input

    Returns:
        True if sentence appears complete
    """
    # Basic heuristic: ends with period/question/exclamation or is reasonably long
    text = text.strip()
    if not text:
        return False

    if text[-1] in ".?!":
        return True

    # If it's a longer, structured sentence, consider it complete
    word_count = len(text.split())
    if word_count >= 5:
        return True

    return False


def calculate_fluency_score(
    filler_count: int,
    repeated_words_count: int,
    hesitation_count: int,
    is_complete: bool,
    word_count: int
) -> float:
    """
    Calculate fluency score (0-100).

    Heuristic based on:
    - Filler words (penalize heavily)
    - Repeated words (penalize moderately)
    - Hesitation patterns (penalize lightly)
    - Sentence completeness
    - Word count (encourage longer utterances)

    Args:
        filler_count: Number of fillers detected
        repeated_words_count: Number of repeated words
        hesitation_count: Number of hesitation patterns
        is_complete: Whether sentence is complete
        word_count: Total words in text

    Returns:
        Fluency score 0-100
    """
    score = 100.0

    # Penalize fillers (most important)
    score -= filler_count * settings.fluency_score_penalty_filler

    # Penalize repeated words
    score -= repeated_words_count * settings.fluency_score_penalty_repetition

    # Penalize hesitation
    score -= hesitation_count * settings.fluency_score_penalty_hesitation

    # Incomplete sentences
    if not is_complete:
        score -= settings.fluency_score_penalty_incomplete

    # Bonus for longer utterances (more natural)
    if 20 < word_count <= 30:
        score += 5
    elif word_count > 30:
        score += 10

    # Clamp to 0-100
    return max(0.0, min(100.0, score))


def analyze_fluency(text: str) -> dict:
    """
    Full fluency analysis.

    Args:
        text: User's text input

    Returns:
        Dictionary with fluency metrics
    """
    filler_words, filler_count = detect_fillers(text)
    repeated_words = detect_repeated_words(text)
    hesitation_patterns = detect_hesitation_patterns(text)
    is_complete = check_sentence_completeness(text)
    word_count = len(text.split())
    sentence_breaks = count_sentence_breaks(text)
    speaking_length_seconds = estimate_speaking_length(word_count)

    filler_density = round(filler_count / max(word_count, 1), 4)
    hesitation_score = round(min(100.0, len(hesitation_patterns) * 20.0 + filler_count * 10.0), 2)

    fluency_score = calculate_fluency_score(
        filler_count=filler_count,
        repeated_words_count=len(repeated_words),
        hesitation_count=len(hesitation_patterns),
        is_complete=is_complete,
        word_count=word_count
    )

    return {
        "filler_words": filler_words,
        "filler_count": filler_count,
        "flagged_words": list(dict.fromkeys(filler_words + repeated_words)),
        "repeated_words": repeated_words,
        "hesitation_patterns": hesitation_patterns,
        "hesitation_score": hesitation_score,
        "filler_density": filler_density,
        "sentence_breaks": sentence_breaks,
        "is_complete": is_complete,
        "fluency_score": round(fluency_score, 2),
        "word_count": word_count,
        "speaking_length_words": word_count,
        "speaking_length_seconds": speaking_length_seconds,
    }
