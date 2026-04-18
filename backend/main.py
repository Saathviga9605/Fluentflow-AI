"""FastAPI application entry point."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.conversation import router as conversation_router
from app.routes.analytics import router as analytics_router
from app.routes.media import router as media_router
from app.core.config import settings


# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Backend for AI-powered English fluency assistant",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware to allow frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes at the requested root paths.
app.include_router(conversation_router, tags=["conversation"])
app.include_router(analytics_router, tags=["analytics"])
app.include_router(media_router, tags=["media"])


@app.on_event("startup")
async def startup_event():
    """Run on application startup."""
    print(f"🚀 {settings.app_name} v{settings.app_version} starting...")
    print(f"📝 Logging to: {settings.log_file}")
    if settings.use_mock_llm:
        print("⚠️  Using mock LLM responses (set OPENAI_API_KEY and USE_MOCK_LLM=False for real API)")
    else:
        print(f"🤖 Connected to {settings.openai_model}")


@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown."""
    print(f"👋 {settings.app_name} shutting down...")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.reload,
        log_level="info"
    )
