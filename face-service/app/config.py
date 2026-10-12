from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: str = "development"
    api_key: str = "troque-esta-chave"
    embedder: str = "insightface"  # insightface | mock
    threshold_login: float = 0.45
    threshold_payment: float = 0.55
    min_face_size_px: int = 80
    min_sharpness: float = 40.0
    max_image_bytes: int = 5 * 1024 * 1024
    liveness_provider: str = "none"

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"


@lru_cache
def get_settings() -> Settings:
    return Settings()
