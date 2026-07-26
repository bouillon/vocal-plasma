"""Kokoro TTS - Text-to-Speech using Kokoro ONNX model."""

__version__ = "0.1.3"

from .core import detect_lang, generate_speech, generate_speech_ru, play_speech

__all__ = ["detect_lang", "generate_speech", "generate_speech_ru", "play_speech"]
