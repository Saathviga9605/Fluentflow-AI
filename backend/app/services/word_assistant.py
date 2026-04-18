"""Word assistance service for suggestions."""

from typing import List, Dict

from typing import Optional, List, Dict

SYNONYM_MAP = {
    "good": ["great", "excellent", "nice", "wonderful"],
    "bad": ["poor", "terrible", "awful", "disappointing"],
    "interesting": ["fascinating", "intriguing", "compelling", "engaging"],
    "said": ["mentioned", "explained", "suggested", "noted"],
    "think": ["believe", "suppose", "consider", "reckon"],
    "important": ["crucial", "vital", "essential", "significant"],
    "want": ["desire", "wish", "seek"],
    "help": ["assist", "aid", "support"],
    "make": ["create", "produce", "build", "craft"],
    "big": ["large", "huge", "substantial", "enormous"],
    "small": ["tiny", "little", "compact", "modest"],
    "go": ["proceed", "move", "travel", "head"],
}


def get_synonyms(word: str) -> List[Dict]:
    """
    Get synonym suggestions for a word.

    Args:
        word: Word to find synonyms for

    Returns:
        List of synonym dictionaries
    """
    word_lower = word.lower()

    if word_lower in SYNONYM_MAP:
        return [
            {
                "type": "synonym",
                "suggestion": syn,
                "explanation": f"Alternative to '{word}'"
            }
            for syn in SYNONYM_MAP[word_lower]
        ]

    return []


def get_phrase_suggestions(text: str) -> List[Dict]:
    """
    Suggest better phrasings.

    Args:
        text: Text to suggest phrasings for

    Returns:
        List of phrase suggestions
    """
    suggestions = []

    # Common awkward phrases and their improvements
    phrase_map = {
        r"i don't know": "I'm not sure",
        r"you know\?": "Right?",
        r"i think that": "I think",
        r"it is like": "It's like",
        r"what is the thing": "What's the thing",
    }

    import re

    for phrase, better in phrase_map.items():
        if re.search(phrase, text, re.IGNORECASE):
            suggestions.append({
                "type": "phrase",
                "suggestion": better,
                "explanation": "More natural phrasing"
            })

    return suggestions


def get_completions(partial_text: str, word_count: int = 3) -> List[Dict]:
    """
    Suggest sentence completions.

    Args:
        partial_text: Partial text/prompt
        word_count: Number of words in suggestions

    Returns:
        List of completion suggestions
    """
    suggestions = []

    # Basic completion suggestions based on context
    common_completions = {
        "I think": [
            "I think it's important",
            "I think we should",
            "I think that's great",
        ],
        "I believe": [
            "I believe that's correct",
            "I believe it's possible",
            "I believe so",
        ],
        "Could you": [
            "Could you help me",
            "Could you explain that",
            "Could you repeat",
        ],
        "I would like": [
            "I would like to know",
            "I would like to try",
            "I would like more information",
        ],
    }

    for key, completions in common_completions.items():
        if partial_text.lower().strip().startswith(key.lower()):
            return [
                {
                    "type": "completion",
                    "suggestion": completion,
                    "explanation": "Common continuation"
                }
                for completion in completions[:3]
            ]

    return suggestions


def get_word_assistance(
    text: str,
    flagged_word: Optional[str] = None
) -> List[Dict]:
    """
    Get comprehensive word assistance.

    Args:
        text: Full text context
        flagged_word: Specific word to get help with (optional)

    Returns:
        List of suggestions
    """
    suggestions = []

    if flagged_word:
        # Get synonyms for flagged word
        synonyms = get_synonyms(flagged_word)
        suggestions.extend(synonyms)
    else:
        # Get phrase suggestions
        phrase_suggestions = get_phrase_suggestions(text)
        suggestions.extend(phrase_suggestions)

        # Get completions
        completion_suggestions = get_completions(text)
        suggestions.extend(completion_suggestions)

        # Fallback suggestions for common filler-heavy sentences.
        import re

        fillers = re.findall(r"\b(um|uh|like|you know)\b", text, re.IGNORECASE)
        if fillers:
            cleaned_text = re.sub(r"\b(um|uh|you know)\b", "", text, flags=re.IGNORECASE)
            cleaned_text = re.sub(r"\s+", " ", cleaned_text).strip()
            cleaned_text = re.sub(r"\s+([,.!?])", r"\1", cleaned_text)
            if cleaned_text and cleaned_text[-1] not in ".?!":
                cleaned_text += "."

            suggestions.append(
                {
                    "type": "phrase",
                    "suggestion": cleaned_text,
                    "explanation": "Remove filler words for smoother speech"
                }
            )

        if not suggestions and text.strip():
            suggestions.append(
                {
                    "type": "phrase",
                    "suggestion": f"{text.strip().rstrip('.?!')}.",
                    "explanation": "A more natural, complete-sentence version"
                }
            )

    return suggestions[:5]  # Limit to top 5 suggestions


