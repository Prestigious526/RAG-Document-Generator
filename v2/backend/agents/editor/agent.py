from backend.agents.ollama_client import OllamaClient
from backend.config.settings import Settings


def validate_section(section_text: str, min_length: int = 100) -> bool:
    """
    Validate that a section meets minimum length requirements.
    """

    if not section_text:
        return False

    cleaned = section_text.strip()

    return len(cleaned) >= min_length


class EditorAgent:
    def __init__(
        self,
        ollama: OllamaClient,
        settings: Settings,
        model: str | None = None,
    ):
        self.ollama = ollama
        self.settings = settings
        self.model = model or settings.ollama_editing_model

    def edit(self, title: str, content: str) -> str:
        """
        Edit and polish a generated document section.
        """

        if not content or not content.strip():
            return content

        try:
            response = self.ollama.generate(
                model=self.model,
                prompt=(
                    "Polish this document section for clarity, readability, "
                    "structure, and grammar while preserving citations, "
                    "technical accuracy, and factual consistency.\n\n"
                    f"Title: {title}\n\n"
                    f"{content}"
                ),
                system=(
                    "You are a professional technical editor. "
                    "Do not remove citations. "
                    "Do not invent facts. "
                    "Do not shorten important technical details."
                ),
            )

            if not response:
                return content

            cleaned_response = response.strip()

            if not validate_section(cleaned_response):
                return content

            return cleaned_response

        except Exception:
            return content