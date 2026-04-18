"""Grammar and usage correction service."""

import re
from typing import Tuple, Optional


def correct_grammar(text: str) -> Tuple[str, Optional[str]]:
    """
    Apply basic grammar corrections.

    This is a basic heuristic-based corrector. For production,
    use specialized libraries like language-tool-python.

    Args:
        text: Original text

    Returns:
        Tuple of (corrected_text, explanation)
    """
    corrected = text
    explanations = []

    # Remove safe filler words that do not change the intended meaning.
    cleaned_text = _remove_safe_fillers(corrected)
    if cleaned_text != corrected:
        corrected = cleaned_text
        explanations.append("Removed filler words")

    # Fix common patterns
    # "I was going to the store" vs "I go to the store"
    corrected, exp1 = _fix_tense_issues(corrected)
    if exp1:
        explanations.append(exp1)

    # "could of" -> "could have"
    corrected, exp2 = _fix_modal_verbs(corrected)
    if exp2:
        explanations.append(exp2)

    # Subject-verb agreement
    corrected, exp3 = _fix_subject_verb_agreement(corrected)
    if exp3:
        explanations.append(exp3)

    # Article usage
    corrected, exp4 = _fix_articles(corrected)
    if exp4:
        explanations.append(exp4)

    explanation = " | ".join(explanations) if explanations else None
    return corrected, explanation


def _remove_safe_fillers(text: str) -> str:
    """Remove conservative filler words while preserving sentence meaning."""
    cleaned = re.sub(r"\b(um|uh|you know)\b", "", text, flags=re.IGNORECASE)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    cleaned = re.sub(r"\s+([,.!?])", r"\1", cleaned)

    if cleaned and cleaned[-1] not in ".?!":
        cleaned += "."

    return cleaned


def _fix_tense_issues(text: str) -> Tuple[str, Optional[str]]:
    """Fix basic tense agreement issues."""
    # "I goes" -> "I go"
    patterns = [
        (r"I goes", "I go"),
        (r"he go\b", "he goes"),
        (r"she go\b", "she goes"),
        (r"it go\b", "it goes"),
    ]

    corrected = text
    for pattern, replacement in patterns:
        if re.search(pattern, corrected, re.IGNORECASE):
            corrected = re.sub(pattern, replacement, corrected, flags=re.IGNORECASE)
            return corrected, "Fixed verb tense agreement"

    return corrected, None


def _fix_modal_verbs(text: str) -> Tuple[str, Optional[str]]:
    """Fix modal verb issues (could of -> could have)."""
    patterns = [
        (r"could of", "could have"),
        (r"would of", "would have"),
        (r"should of", "should have"),
    ]

    corrected = text
    for pattern, replacement in patterns:
        if re.search(pattern, corrected, re.IGNORECASE):
            corrected = re.sub(pattern, replacement, corrected, flags=re.IGNORECASE)
            return corrected, "Fixed modal verb form"

    return corrected, None


def _fix_subject_verb_agreement(text: str) -> Tuple[str, Optional[str]]:
    """Fix subject-verb agreement issues."""
    # "The students is" -> "The students are"
    patterns = [
        (r"(students|people|they) is\b", r"\1 are"),
        (r"(team|group|class) are\b", r"\1 is"),
    ]

    corrected = text
    for pattern, replacement in patterns:
        if re.search(pattern, corrected, re.IGNORECASE):
            corrected = re.sub(pattern, replacement, corrected, flags=re.IGNORECASE)
            return corrected, "Fixed subject-verb agreement"

    return corrected, None


def _fix_articles(text: str) -> Tuple[str, Optional[str]]:
    """Fix article usage (a/an/the)."""
    # "I go to a university" -> "I go to a university" (correct)
    # "I go to university" -> might need "the" depending on context

    # For now, basic check: "a" before vowel -> "an"
    corrected = re.sub(
        r"\ba ([aeiou])",
        r"an \1",
        text,
        flags=re.IGNORECASE
    )

    if corrected != text:
        return corrected, "Fixed article usage"

    return corrected, None


def suggest_word_improvements(text: str) -> list:
    """
    Suggest word usage improvements.

    Args:
        text: Original text

    Returns:
        List of improvement suggestions
    """
    suggestions = []

    # Word replacement suggestions
    replacements = {
        r"\bcan(?:'t| not)\b": {
            "suggestion": "could not",
            "explanation": "More formal/emphatic"
        },
        r"\bthing\b": {
            "suggestion": "issue/matter/topic",
            "explanation": "More specific vocabulary"
        },
        r"\bstuff\b": {
            "suggestion": "items/matters",
            "explanation": "More formal vocabulary"
        },
        r"\bgot\b": {
            "suggestion": "received/have",
            "explanation": "Clearer usage"
        },
    }

    for pattern, info in replacements.items():
        if re.search(pattern, text, re.IGNORECASE):
            suggestions.append({
                "type": "word_choice",
                "original": re.findall(pattern, text, re.IGNORECASE)[0],
                "suggestion": info["suggestion"],
                "explanation": info["explanation"]
            })

    return suggestions
