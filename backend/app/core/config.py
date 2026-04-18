from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)

    # API Settings
    app_name: str = "FluentFlow AI"
    app_version: str = "1.0.0"
    debug: bool = False

    # LLM Settings
    openrouter_api_key: str = ""
    openrouter_model: str = "openai/gpt-4o-mini"
    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    openrouter_site_url: str = "http://localhost:3000"
    openrouter_app_name: str = "FluentFlow AI"

    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    use_mock_llm: bool = True

    # Speech settings
    use_mock_stt: bool = True
    use_mock_tts: bool = False
    whisper_backend: str = "faster-whisper"
    whisper_model_size: str = "base"
    tts_language: str = "en"

    # Logging
    log_file: str = "logs/fluency_analysis.csv"
    log_dir: str = "logs"
    sqlite_db_path: str = "data/fluency.db"

    # Memory and analytics
    max_memory_messages: int = 20
    history_limit: int = 50
    fluency_fillers: list[str] = ["um", "uh", "like", "you know"]
    fluency_score_penalty_filler: float = 8.0
    fluency_score_penalty_repetition: float = 5.0
    fluency_score_penalty_hesitation: float = 3.0
    fluency_score_penalty_incomplete: float = 10.0

    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    reload: bool = False


settings = Settings()
