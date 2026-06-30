"""Application configuration, read from env vars and files."""
import os
from pathlib import Path
from functools import cached_property


def _read_file(path: str) -> str:
    """Read a secret from a file path, falling back to env var."""
    if os.path.isfile(path):
        return Path(path).read_text().strip()
    return os.getenv(path, "")


class Settings:
    @cached_property
    def secret_key(self) -> str:
        return _read_file(os.getenv("SECRET_KEY_FILE", ""))

    @cached_property
    def database_url(self) -> str:
        return os.getenv("DATABASE_URL", "postgresql:///hosting_portal?host=/run/postgresql")

    @cached_property
    def incus_socket(self) -> str:
        return os.getenv("INCUS_SOCKET", "/var/lib/incus/unix.socket")

    @cached_property
    def pterodactyl_url(self) -> str:
        return os.getenv("PTERODACTYL_URL", "http://127.0.0.1:8080")

    @cached_property
    def pterodactyl_api_key(self) -> str:
        return _read_file(os.getenv("PTERODACTYL_API_KEY_FILE", ""))

    @cached_property
    def stripe_secret_key(self) -> str:
        return _read_file(os.getenv("STRIPE_SECRET_KEY_FILE", ""))

    @cached_property
    def stripe_webhook_secret(self) -> str:
        return _read_file(os.getenv("STRIPE_WEBHOOK_SECRET_FILE", ""))
    @cached_property
    def cors_origins(self) -> list[str]:
        raw = "https://portal.zentryx.pt,http://localhost:8000,http://127.0.0.1:8000,http://192.168.1.237:8000"
        return [o.strip() for o in raw.split(",")]


settings = Settings()
