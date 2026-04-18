"""Helper utilities."""

import time
from functools import wraps
from typing import Any, Callable


def measure_time(func: Callable) -> Callable:
    """
    Decorator to measure function execution time.

    Args:
        func: Function to measure

    Returns:
        Wrapped function that returns (result, time_ms)
    """
    @wraps(func)
    async def async_wrapper(*args, **kwargs) -> tuple:
        start = time.time()
        result = await func(*args, **kwargs)
        elapsed_ms = (time.time() - start) * 1000
        return result, elapsed_ms

    @wraps(func)
    def sync_wrapper(*args, **kwargs) -> tuple:
        start = time.time()
        result = func(*args, **kwargs)
        elapsed_ms = (time.time() - start) * 1000
        return result, elapsed_ms

    # Return appropriate wrapper
    import inspect
    if inspect.iscoroutinefunction(func):
        return async_wrapper
    else:
        return sync_wrapper


def truncate_text(text: str, max_length: int = 100) -> str:
    """
    Truncate text to max length with ellipsis.

    Args:
        text: Text to truncate
        max_length: Maximum length

    Returns:
        Truncated text
    """
    if len(text) <= max_length:
        return text
    return text[:max_length - 3] + "..."


def clean_text(text: str) -> str:
    """
    Clean user input text.

    Args:
        text: Raw text

    Returns:
        Cleaned text
    """
    # Remove extra whitespace
    text = " ".join(text.split())

    # Remove leading/trailing whitespace
    text = text.strip()

    return text
