from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/trackprice"
    REDIS_URL: str = "redis://localhost:6379/0"
    SECRET_KEY: str = "change-me-in-production"
    PROXY_HOST: str = ""
    PROXY_USER: str = ""
    PROXY_PASS: str = ""
    APPLE_TEAM_ID: str = ""
    APPLE_KEY_ID: str = ""
    APPLE_BUNDLE_ID: str = ""
    APNS_KEY_ID: str = ""
    APNS_TEAM_ID: str = ""
    APNS_BUNDLE_ID: str = ""
    APNS_PRIVATE_KEY: str = ""
    APNS_SANDBOX: bool = True
    ENVIRONMENT: str = "dev"

    class Config:
        env_file = ".env"


settings = Settings()
