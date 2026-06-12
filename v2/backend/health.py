import socket
import time

import httpx

from backend.config.settings import get_settings


def _http_health(name: str, url: str, timeout: int = 3) -> dict:
    started = time.perf_counter()
    try:
        with httpx.Client(timeout=timeout) as client:
            response = client.get(url)
        return {
            "name": name,
            "status": "ok" if response.is_success else "error",
            "latency_ms": round((time.perf_counter() - started) * 1000, 1),
            "detail": response.status_code,
        }
    except httpx.RequestError as exc:
        return {
            "name": name,
            "status": "error",
            "latency_ms": round((time.perf_counter() - started) * 1000, 1),
            "detail": str(exc),
        }


def _tcp_health(name: str, host: str, port: int, timeout: float = 2.0) -> dict:
    started = time.perf_counter()
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return {
                "name": name,
                "status": "ok",
                "latency_ms": round((time.perf_counter() - started) * 1000, 1),
                "detail": f"{host}:{port}",
            }
    except OSError as exc:
        return {
            "name": name,
            "status": "error",
            "latency_ms": round((time.perf_counter() - started) * 1000, 1),
            "detail": str(exc),
        }


def deep_health() -> dict:
    settings = get_settings()
    checks = [
        _http_health("ollama", f"{settings.ollama_base_url.rstrip('/')}/api/tags"),
        _http_health("qdrant", f"{settings.qdrant_url.rstrip('/')}/collections"),
        _tcp_health("postgres", settings.postgres_host, settings.postgres_port),
    ]
    redis_host = settings.redis_url.split("@")[-1].replace("redis://", "").split("/")[0].split(":")[0]
    redis_port = int(settings.redis_url.split(":")[-1].split("/")[0]) if ":" in settings.redis_url else 6379
    checks.append(_tcp_health("redis", redis_host, redis_port))
    overall = "ok" if all(check["status"] == "ok" for check in checks) else "degraded"
    return {"status": overall, "checks": checks}
