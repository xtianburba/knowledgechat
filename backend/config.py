"""Configuration settings for the application"""
from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List


class Settings(BaseSettings):
    """Application settings"""
    
    # Gemini API
    gemini_api_key: str = ""
    
    # Zendesk
    zendesk_subdomain: str = ""
    zendesk_email: str = ""
    zendesk_api_token: str = ""
    zendesk_auto_sync: bool = False
    zendesk_sync_hour: int = 2
    zendesk_sync_minute: int = 0
    
    @field_validator('zendesk_auto_sync', mode='before')
    @classmethod
    def parse_bool(cls, v):
        """Convert string to bool for zendesk_auto_sync"""
        if isinstance(v, bool):
            return v
        if isinstance(v, str):
            return v.lower() in ('true', '1', 'yes', 'on')
        return False
    
    # JWT
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expiration_hours: int = 24
    
    # ChromaDB
    chroma_db_path: str = "./chroma_db"
    
    # CORS
    cors_origins: str = "http://localhost:3000,http://localhost:8000"
    
    def get_cors_origins(self) -> List[str]:
        """Parse CORS origins from comma-separated string"""
        if isinstance(self.cors_origins, str):
            return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]
        return ["http://localhost:3000", "http://localhost:8000"]
    
    # Files
    upload_dir: str = "./uploads"
    max_upload_size: int = 10 * 1024 * 1024  # 10MB
    
    # Admin
    admin_email: str = "admin@example.com"
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Ignore extra fields in .env file that aren't defined here
        


settings = Settings()


