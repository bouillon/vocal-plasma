#!/bin/bash
# Wrapper script for Kokoro TTS speak command

# Set model and voices paths to the installed locations
export KOKORO_MODEL_PATH="/usr/share/kokoro-tts/kokoro-v1.0.onnx"
export KOKORO_VOICES_PATH="/usr/share/kokoro-tts/voices-v1.0.bin"

cd /opt/kokoro-tts

# Use the virtual environment created during package installation
if [ -d "/opt/kokoro-tts/.venv" ]; then
    /opt/kokoro-tts/.venv/bin/python -m kokoro_tts.cli "$@"
else
    echo "Error: Kokoro TTS virtual environment not found!"
    echo "Please reinstall the package: dpkg -i vocal-plasma.deb"
    exit 1
fi