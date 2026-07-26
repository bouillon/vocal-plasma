#!/usr/bin/env python3
"""Generate demo MP3 files for different voices."""

import sys
from pathlib import Path
import soundfile as sf  # type: ignore[import-untyped]
from kokoro_tts.core import generate_speech

# Demo text
DEMO_TEXT = "Hello! This is Vocal Plasma, a high-quality text-to-speech system for KDE Plasma desktop. Select any text and press Alt Escape to hear it spoken."

# Voices to demo
VOICES = {
    "af_sky": "American Female - Sky",
    "am_adam": "American Male - Adam",
    "bf_emma": "British Female - Emma",
    "bm_george": "British Male - George",
}

def main():
    output_dir = Path("demos")
    output_dir.mkdir(exist_ok=True)

    print("Generating demo audio files...")
    print(f"Text: {DEMO_TEXT}\n")

    for voice_id, voice_name in VOICES.items():
        print(f"Generating: {voice_name}...")

        # Generate speech
        samples, sample_rate = generate_speech(DEMO_TEXT, voice=voice_id)

        # Save as WAV
        wav_file = output_dir / f"demo_{voice_id}.wav"
        sf.write(wav_file, samples, sample_rate)
        print(f"  ✓ Saved: {wav_file}")

    print(f"\n✅ Done! Demo files in: {output_dir}/")
    print("\nTo convert to MP3:")
    print("  apt-get install ffmpeg")
    print("  cd demos && for f in *.wav; do ffmpeg -i \"$f\" \"${f%.wav}.mp3\"; done")

if __name__ == "__main__":
    main()
