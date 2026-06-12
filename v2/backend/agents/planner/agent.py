import json
import re

from backend.agents.ollama_client import OllamaClient
from backend.config.settings import Settings


DEFAULT_SECTIONS = [
    "Executive Summary",
    "Background",
    "Requirements",
    "System Architecture",
    "Implementation Plan",
    "Validation and Risks",
    "Conclusion",
]


class PlannerAgent:
    def __init__(
        self,
        ollama: OllamaClient,
        settings: Settings,
        model: str | None = None,
    ):
        self.ollama = ollama
        self.settings = settings
        self.model = model or settings.ollama_planning_model

    def plan(
        self,
        prompt: str,
        required_sections: list[str] | None = None,
    ) -> list[dict]:
        """
        Generate a structured document plan.
        """

        if required_sections:
            titles = required_sections
        else:
            titles = self._ask_ollama(prompt)

            if not titles:
                titles = DEFAULT_SECTIONS

        return [
            {
                "id": str(index + 1),
                "title": title.strip(),
                "dependencies": [] if index == 0 else [str(index)],
                "required_context": [
                    title.strip(),
                    prompt[:180],
                ],
                "template_constraints": {},
            }
            for index, title in enumerate(titles)
            if title and title.strip()
        ]

    def _ask_ollama(self, prompt: str) -> list[str]:
        """
        Ask Ollama to generate document sections.
        """

        try:
            response = self.ollama.generate(
                model=self.model,
                prompt=(
                    "Create a concise document section outline.\n\n"
                    "Return ONLY a valid JSON array of section titles.\n\n"
                    f"Request:\n{prompt}"
                ),
                system=(
                    "You are a document planning agent.\n"
                    "Return only valid JSON.\n"
                    "Do not include markdown.\n"
                    "Do not include explanations."
                ),
            )

            if not response:
                return DEFAULT_SECTIONS

            response = response.strip()

            try:
                parsed = json.loads(response)

                if isinstance(parsed, list):
                    return [str(item).strip() for item in parsed if str(item).strip()]

            except json.JSONDecodeError:
                pass

            lines = [
                re.sub(r"^[0-9.\-\s]+", "", line).strip()
                for line in response.splitlines()
            ]

            cleaned = [line for line in lines if line]

            return cleaned[:8] if cleaned else DEFAULT_SECTIONS

        except Exception:
            return DEFAULT_SECTIONS