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


class ValidatorAgent:
    def __init__(
        self,
        ollama: OllamaClient,
        settings: Settings,
        model: str | None = None,
    ):
        self.ollama = ollama
        self.settings = settings
        self.model = model or settings.ollama_validation_model

    def validate(self, title: str, content: str) -> dict:
        """
        Validate generated document content.
        """

        if not content or not content.strip():
            return {
                "valid": False,
                "reason": "Empty content",
            }

        length_valid = validate_section(content)

        prompt = (
            "Validate the following document section.\n\n"
            "Check for:\n"
            "- Clarity\n"
            "- Technical consistency\n"
            "- Citation preservation\n"
            "- Logical structure\n"
            "- Hallucinated facts\n\n"
            f"Title: {title}\n\n"
            f"Content:\n{content}\n\n"
            "Return a concise validation summary."
        )

        try:
            response = self.ollama.generate(
                model=self.model,
                prompt=prompt,
                system=(
                    "You are a technical document validator. "
                    "Detect hallucinations, structural issues, "
                    "missing citations, and weak sections."
                ),
            )

            return {
                "valid": length_valid,
                "length_valid": length_valid,
                "summary": response.strip() if response else "Validation completed",
            }

        except Exception as exc:
            return {
                "valid": length_valid,
                "length_valid": length_valid,
                "summary": f"Validation failed: {str(exc)}",
            }