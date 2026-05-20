"""
Gemini client using the google-genai SDK with Vertex AI backend.
Initialises with GCP project/region and provides a simple generate() method.
"""

from google import genai
from google.genai.types import GenerateContentConfig


class GeminiClient:
    """Wrapper around Gemini 1.5 Flash via google-genai SDK (Vertex AI backend)."""

    MODEL_NAME = "gemini-1.5-flash-001"

    def __init__(self, project_id: str, region: str) -> None:
        """
        Initialise the genai client pointed at Vertex AI.

        Args:
            project_id: GCP project ID (e.g. 'aiseekho-service-orchestrator').
            region: GCP region (e.g. 'us-central1').

        Raises:
            ValueError: If project_id is empty.
        """
        if not project_id:
            raise ValueError(
                "GCP_PROJECT_ID is required to initialise the Gemini client."
            )

        self._client = genai.Client(
            vertexai=True,
            project=project_id,
            location=region,
        )
        self._project_id = project_id
        self._region = region

    def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        max_tokens: int = 200,
    ) -> str:
        """
        Call Gemini with a system + user prompt and return the text response.

        Args:
            system_prompt: System instruction for the model.
            user_prompt: The user-facing prompt text.
            max_tokens: Maximum output tokens (keep small per docs).

        Returns:
            str: The model's text response.
        """
        config = GenerateContentConfig(
            system_instruction=system_prompt,
            max_output_tokens=max_tokens,
            temperature=0.2,  # low creativity for structured extraction
        )

        response = self._client.models.generate_content(
            model=self.MODEL_NAME,
            contents=user_prompt,
            config=config,
        )

        return response.text
