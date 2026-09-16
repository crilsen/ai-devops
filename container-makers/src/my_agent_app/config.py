import os

DEFAULT_DATABASE_URL = "postgresql+asyncpg://app:app123@localhost:5432/my_agent_app"
DEFAULT_LLM_MODEL = "anthropic:claude-sonnet-5"


def get_database_url() -> str:
    return os.environ.get("DATABASE_URL") or DEFAULT_DATABASE_URL


def get_llm_model() -> str:
    return os.environ.get("LLM_MODEL") or DEFAULT_LLM_MODEL


def get_anthropic_api_key() -> str | None:
    return os.environ.get("ANTHROPIC_API_KEY") or None
