"""Command-line interface for the speak command."""

import argparse
import sys

import numpy as np
from numpy.typing import NDArray

from .core import detect_lang, generate_speech, generate_speech_ru, play_speech


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="speak",
        description="Offline TTS: English (Kokoro) + Russian (Piper). Reads text from stdin.",
        epilog=(
            "examples:\n"
            "  echo 'Hello world' | speak\n"
            "  echo 'Миру мир!' | speak            # Russian auto-detected\n"
            "  echo 'Hello' | speak -v am_adam -s 1.2\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "-l", "--lang", choices=["auto", "en", "ru"], default="auto",
        help="language (default: auto — Cyrillic text switches to ru)",
    )
    parser.add_argument(
        "-v", "--voice", default="af_sky",
        help="English voice: af_sky af_bella af_nicole af_sarah am_michael "
             "am_adam bf_emma bf_isabella bm_george bm_lewis",
    )
    parser.add_argument("-s", "--speed", type=float, default=1.0, help="speech speed (default: 1.0)")
    args = parser.parse_args()

    text: str = sys.stdin.read().strip()
    if not text:
        print("No text received. Usage: echo 'text' | speak")
        sys.exit(1)

    lang: str = detect_lang(text) if args.lang == "auto" else args.lang
    print(f"🗣️  [{lang}] {text[:50]}...")

    try:
        samples: NDArray[np.float32]
        sample_rate: int
        if lang == "ru":
            samples, sample_rate = generate_speech_ru(text, speed=args.speed)
        else:
            samples, sample_rate = generate_speech(text, voice=args.voice, speed=args.speed)
        play_speech(samples, sample_rate)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
