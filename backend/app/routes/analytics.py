"""Analytics routes for progress tracking and conversation history."""

from fastapi import APIRouter, HTTPException

from app.services.progress_service import progress_service
from app.schemas.analytics import ProgressResponse, HistoryResponse


router = APIRouter()


@router.get("/progress/{user_id}", response_model=ProgressResponse)
async def get_progress(user_id: str):
    """Return a user's learning progress summary."""
    try:
        return ProgressResponse(**progress_service.get_progress(user_id))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to load progress: {exc}") from exc


@router.get("/history/{user_id}", response_model=HistoryResponse)
async def get_history(user_id: str):
    """Return a user's past conversations."""
    try:
        history = progress_service.get_history(user_id)
        return HistoryResponse(user_id=user_id, conversations=history)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to load history: {exc}") from exc
