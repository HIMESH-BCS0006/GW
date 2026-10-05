import os
from typing import Optional
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Waypoint Delivery Planning System"
    ENV: str = "development"
    
    # Business Clock & Demo Mode (D11)
    DEMO_MODE: bool = True
    DEMO_NOW: str = "2025-07-31T14:00:00+05:30"
    SEED_DELIVERY_DATE: str = "2025-08-01"
    TIMEZONE: str = "Asia/Colombo"
    
    # Database
    DATABASE_URL: str = "sqlite:///./waypoint_dev.db"
    
    # Auth & Security
    SECRET_KEY: str = "waypoint_super_secret_jwt_key_change_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 480
    
    # Operational Config Defaults
    DELAY_ALERT_MIN: int = 15
    RELOAD_BUFFER_MIN: int = 0
    
    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
