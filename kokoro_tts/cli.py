"""Command-line interface for Kokoro TTS."""

import sys
from numpy.typing import NDArray
import numpy as np
from .core import generate_speech, play_speech


def main() -> None:
    """Main entry point for the speak command."""
    # Read text from stdin (piped input)
    text: str
    try:
        text = sys.stdin.read().strip()
    except Exception:
        text = ""

    if not text:
        print("No text received. Usage: echo 'text' | speak")
        sys.exit(1)

    print(f"🗣️  Speaking: {text[:50]}...")

    # Generate and play audio
    try:
        samples: NDArray[np.float32]
        sample_rate: int
        samples, sample_rate = generate_speech(text)
        play_speech(samples, sample_rate)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
