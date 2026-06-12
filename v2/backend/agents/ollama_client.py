import httpx


class OllamaClient:
    def __init__(self, base_url: str, enabled: bool = True):
        self.base_url = base_url.rstrip("/")
        self.enabled = enabled
        self.client = httpx.Client(timeout=180)

    def generate(self, model: str, prompt: str, system: str | None = None) -> str:
        if not self.enabled:
            return ""
        payload = {"model": model, "prompt": prompt, "stream": False}
        if system:
            payload["system"] = system
        try:
            response = self.client.post(f"{self.base_url}/api/generate", json=payload)
            response.raise_for_status()
            return response.json().get("response", "").strip()
        except httpx.RequestError:
            return ""

    def __del__(self):
        self.client.close()
