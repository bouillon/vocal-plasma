"""Kokoro TTS - Text-to-Speech using Kokoro ONNX model."""

__version__ = "0.1.0"

from .core import generate_speech, play_speech

__all__ = ["generate_speech", "play_speech"]
