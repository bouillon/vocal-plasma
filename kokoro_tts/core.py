"""Core functionality for Kokoro TTS."""

import subprocess
import tempfile
import logging
import os
from pathlib import Path
from typing import Optional
import numpy as np
from numpy.typing import NDArray
import soundfile as sf  # type: ignore[import-untyped]
from kokoro_onnx import Kokoro  # type: ignore[import-untyped]

# Suppress internal logging to keep output clean
logging.getLogger("kokoro_onnx").setLevel(logging.ERROR)

# Global model instance (lazy loaded)
_kokoro_instance: Optional[Kokoro] = None


def find_model_files() -> tuple[str, str]:
    """
    Find model files in standard locations.

    Search order:
    1. Environment variables KOKORO_MODEL_PATH and KOKORO_VOICES_PATH
    2. Current working directory
    3. User data directory (~/.local/share/kokoro-tts/)
    4. System data directory (/usr/local/share/kokoro-tts/)
    5. /var/local/speach/

    Returns:
        tuple: (model_path, voices_path)

    Raises:
        FileNotFoundError: If model files cannot be found
    """
    model_name: str = "kokoro-v1.0.onnx"
    voices_name: str = "voices-v1.0.bin"

    # Check environment variables first
    env_model: Optional[str] = os.environ.get("KOKORO_MODEL_PATH")
    env_voices: Optional[str] = os.environ.get("KOKORO_VOICES_PATH")
    if env_model and env_voices and Path(env_model).exists() and Path(env_voices).exists():
        return env_model, env_voices

    # Standard search paths
    search_paths = [
        Path.cwd(),  # Current directory
        Path.home() / ".local" / "share" / "kokoro-tts",  # User directory
        Path("/usr/share/kokoro-tts"),  # Debian package location
        Path("/usr/local/share/kokoro-tts"),  # System directory
        Path("/var/local/speach"),  # Alternative system directory
    ]

    for path in search_paths:
        model_path = path / model_name
        voices_path = path / voices_name
        if model_path.exists() and voices_path.exists():
            return str(model_path), str(voices_path)

    # Not found
    raise FileNotFoundError(
        f"Could not find model files '{model_name}' and '{voices_name}' in any of:\n" +
        "\n".join(f"  - {p}" for p in search_paths) +
        "\n\nSet KOKORO_MODEL_PATH and KOKORO_VOICES_PATH environment variables, " +
        "or install models to one of the above locations."
    )


def get_kokoro(model_path: Optional[str] = None, voices_path: Optional[str] = None) -> Kokoro:
    """
    Get or create the Kokoro model instance.

    Args:
        model_path: Optional path to model file. If None, searches standard locations.
        voices_path: Optional path to voices file. If None, searches standard locations.
    """
    global _kokoro_instance
    if _kokoro_instance is None:
        if model_path is None or voices_path is None:
            model_path, voices_path = find_model_files()
        _kokoro_instance = Kokoro(model_path, voices_path)
    return _kokoro_instance


def generate_speech(
    text: str,
    voice: str = "af_sky",
    speed: float = 1.0,
    lang: str = "en-us",
    padding_duration: float = 0.3
) -> tuple[NDArray[np.float32], int]:
    """
    Generate speech samples from text.

    Args:
        text: The text to convert to speech
        voice: Voice to use (default: 'af_sky')
            American Female: af_sky, af_bella, af_nicole, af_sarah
            American Male: am_michael, am_adam
            British Female: bf_emma, bf_isabella
            British Male: bm_george, bm_lewis
        speed: Speech speed multiplier (default: 1.0)
        lang: Language code (default: 'en-us')
        padding_duration: Silence padding in seconds at the beginning (default: 0.3)

    Returns:
        tuple: (samples, sample_rate)
    """
    kokoro: Kokoro = get_kokoro()

    samples: NDArray[np.float32]
    sample_rate: int
    samples, sample_rate = kokoro.create(
        text,
        voice=voice,
        speed=speed,
        lang=lang
    )

    # Add silence padding at the beginning to prevent cutoff
    if padding_duration > 0:
        padding_samples: int = int(sample_rate * padding_duration)
        silence: NDArray[np.float32] = np.zeros(padding_samples, dtype=samples.dtype)
        samples = np.concatenate([silence, samples])

    return samples, sample_rate


def play_speech(samples: NDArray[np.float32], sample_rate: int, player: str = "paplay") -> None:
    """
    Play audio samples using the specified player.

    Args:
        samples: Audio samples array
        sample_rate: Sample rate in Hz
        player: Audio player to use ('paplay' or 'aplay')
    """
    # Save to temporary WAV file and play
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        tmp_path: str = tmp.name
        sf.write(tmp_path, samples, sample_rate)  # type: ignore[reportUnknownMemberType]

    # Fix XDG_RUNTIME_DIR for PulseAudio if running as non-root
    env: dict[str, str] = os.environ.copy()
    if os.getuid() != 0 and env.get('XDG_RUNTIME_DIR', '').endswith('/0'):
        # Fix incorrect XDG_RUNTIME_DIR (set to root's dir)
        env['XDG_RUNTIME_DIR'] = f"/run/user/{os.getuid()}"

    # Play using the specified player
    subprocess.run([player, tmp_path], check=True, env=env)

    # Clean up
    os.unlink(tmp_path)
