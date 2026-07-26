"""Core functionality for Kokoro TTS."""

import re
import subprocess
import tempfile
import logging
import os
from pathlib import Path
from typing import TYPE_CHECKING, Optional
import numpy as np
from numpy.typing import NDArray
import soundfile as sf  # type: ignore[import-untyped]
from kokoro_onnx import Kokoro  # type: ignore[import-untyped]

if TYPE_CHECKING:
    from piper import PiperVoice

# Suppress internal logging to keep output clean
logging.getLogger("kokoro_onnx").setLevel(logging.ERROR)

# Global model instances (lazy loaded)
_kokoro_instance: Optional[Kokoro] = None
_piper_instance: "PiperVoice | None" = None

_CYRILLIC = re.compile(r"[а-яё]", re.IGNORECASE)
_LATIN = re.compile(r"[a-z]", re.IGNORECASE)


def detect_lang(text: str) -> str:
    """'ru' if Cyrillic letters are present and not outnumbered by Latin, else 'en'."""
    cyr = len(_CYRILLIC.findall(text))
    if cyr == 0:
        return "en"
    return "ru" if cyr >= len(_LATIN.findall(text)) else "en"


def _search_dirs() -> list[Path]:
    """Model search locations, in priority order."""
    return [
        Path.cwd(),
        Path.home() / ".local" / "share" / "kokoro-tts",
        Path("/usr/share/kokoro-tts"),
        Path("/usr/local/share/kokoro-tts"),
        Path("/var/local/speach"),
    ]


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

    search_paths = _search_dirs()

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


def find_piper_model() -> str:
    """Find the Russian Piper voice model (*.onnx with its .onnx.json next to it)."""
    env_model: str | None = os.environ.get("PIPER_MODEL_PATH")
    if env_model and Path(env_model).exists():
        return env_model

    name = "ru_RU-irina-medium.onnx"
    for path in _search_dirs():
        model = path / name
        if model.exists() and model.with_suffix(".onnx.json").exists():
            return str(model)

    raise FileNotFoundError(
        f"Russian voice '{name}' not found in standard locations. "
        "Set PIPER_MODEL_PATH or install the model."
    )


def get_piper(model_path: str | None = None) -> "PiperVoice":
    """Get or create the Piper (Russian) model instance."""
    global _piper_instance
    if _piper_instance is None:
        from piper import PiperVoice  # lazy: not needed for English

        if model_path is None:
            model_path = find_piper_model()
        _piper_instance = PiperVoice.load(model_path)
    return _piper_instance


def _pad_silence(
    samples: NDArray[np.float32], sample_rate: int, duration: float
) -> NDArray[np.float32]:
    """Prepend silence to prevent playback cutoff."""
    if duration <= 0:
        return samples
    silence: NDArray[np.float32] = np.zeros(int(sample_rate * duration), dtype=samples.dtype)
    return np.concatenate([silence, samples])


def generate_speech_ru(
    text: str,
    speed: float = 1.0,
    padding_duration: float = 0.3,
) -> tuple[NDArray[np.float32], int]:
    """
    Generate Russian speech samples via Piper.

    Returns:
        tuple: (samples, sample_rate)
    """
    from piper import SynthesisConfig  # lazy: not needed for English

    voice = get_piper()
    config = SynthesisConfig(length_scale=1.0 / speed) if speed != 1.0 else None
    chunks = list(voice.synthesize(text, syn_config=config))

    sample_rate: int = chunks[0].sample_rate if chunks else voice.config.sample_rate
    parts = [chunk.audio_float_array for chunk in chunks]
    samples: NDArray[np.float32] = (
        np.concatenate(parts) if parts else np.zeros(0, dtype=np.float32)
    )

    return _pad_silence(samples, sample_rate, padding_duration), sample_rate


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

    return _pad_silence(samples, sample_rate, padding_duration), sample_rate


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
