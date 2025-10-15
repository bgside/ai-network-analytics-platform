from typing import List, Optional
from pydantic import BaseSettings, validator
import secrets


class Settings(BaseSettings):
    # API Configuration
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = secrets.token_urlsafe(32)
    PROJECT_NAME: str = "AI Network Analytics Platform"
    VERSION: str = "1.0.0"
    DESCRIPTION: str = "Advanced AI-powered network analytics and optimization platform"

    # Server Configuration
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True

    # CORS Configuration
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:3000",  # React dev server
        "http://localhost:8000",  # FastAPI server
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
    ]

    # Database Configuration
    DATABASE_URL: str = "sqlite:///./network_analytics.db"
    REDIS_URL: str = "redis://localhost:6379"

    # ML Configuration
    ML_MODEL_PATH: str = "./models"
    TRAINING_DATA_PATH: str = "./data"
    MODEL_UPDATE_INTERVAL: int = 3600  # 1 hour

    # Kafka Configuration
    KAFKA_BOOTSTRAP_SERVERS: str = "localhost:9092"
    KAFKA_TOPICS: List[str] = [
        "network.telemetry",
        "device.metrics",
        "anomaly.detection"
    ]

    # Monitoring Configuration
    PROMETHEUS_ENABLED: bool = True
    GRAFANA_URL: str = "http://localhost:3001"

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings()
