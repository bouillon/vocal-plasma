#!/bin/bash

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
MODEL_URL="https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx"
VOICES_URL="https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin"
# ---------------------

echo "🚀 Starting Kokoro TTS (2025) Setup..."

# 1. Check Python3
echo "🐍 Checking for Python 3..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed!"
    echo "📥 Installing Python 3..."

    apt-get update
    apt-get install -y python3 python3-pip

    if [ $? -ne 0 ]; then
        echo "❌ Failed to install Python 3. Please install manually."
        exit 1
    fi
fi
echo "✅ Python 3 is available: $(python3 --version)"

# 2. Check and Install uv
echo "📦 Checking for uv package manager..."
if ! command -v uv &> /dev/null; then
    echo "⚠️  uv is not installed!"
    echo "📥 Installing uv from https://astral.sh/uv..."

    if command -v curl &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget &> /dev/null; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        echo "❌ Neither curl nor wget available. Cannot download uv installer."
        echo "   Please install curl or wget first."
        exit 1
    fi

    # Source the shell profile to make uv available in current session
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v uv &> /dev/null; then
        echo "❌ uv installation failed. Please check the output above."
        exit 1
    fi
fi
echo "✅ uv is available: $(uv --version)"

# 3. Check and Install System Dependencies
echo "📦 Checking system dependencies..."

REQUIRED_PACKAGES=("pulseaudio-utils" "wl-clipboard" "curl" "wget")
MISSING_PACKAGES=()

# Check if packages are installed
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

# Install missing packages if any
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "⚠️  Missing packages: ${MISSING_PACKAGES[*]}"
    echo "📥 Installing missing packages..."

    apt-get update
    apt-get install -y "${MISSING_PACKAGES[@]}"

    if [ $? -ne 0 ]; then
        echo "❌ Failed to install packages. Please run as root or install manually:"
        echo "   apt-get install -y ${MISSING_PACKAGES[*]}"
        exit 1
    fi
    echo "✅ All required packages installed successfully!"
else
    echo "✅ All required system packages are already installed."
fi

# 2. Create Directory Structure
echo "📁 Creating installation directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

# 3. Initialize uv Project
echo "🐍 Initializing uv project with Python 3.13..."
if [ ! -f "pyproject.toml" ]; then
    uv init --python 3.13 --name kokoro-tts --no-readme
fi

# 4. Install Python Libraries
echo "📥 Adding Python dependencies (Kokoro ONNX, SoundDevice, NumPy, SciPy)..."
uv add kokoro-onnx sounddevice numpy scipy

# 5. Download Models
echo "⬇️ Downloading Kokoro v1.0 Model and Voices..."
if [ ! -s "kokoro-v1.0.onnx" ]; then
    echo "Downloading model (310MB)..."
    wget -q --show-progress "$MODEL_URL" -O kokoro-v1.0.onnx
else
    echo "✅ Model file already exists ($(du -h kokoro-v1.0.onnx | cut -f1))."
fi

if [ ! -s "voices-v1.0.bin" ]; then
    echo "Downloading voices..."
    wget -q --show-progress "$VOICES_URL" -O voices-v1.0.bin
else
    echo "✅ Voices file already exists ($(du -h voices-v1.0.bin | cut -f1))."
fi

# 6. Create the 'speak.py' script
echo "📝 Creating the python playback script..."
cat << 'EOF' > speak.py
import sys
import sounddevice as sd
from kokoro_onnx import Kokoro
import logging
import numpy as np
from scipy import signal

# Suppress internal logging to keep output clean
logging.getLogger("kokoro_onnx").setLevel(logging.ERROR)

def main():
    # Load model and voices
    try:
        kokoro = Kokoro("kokoro-v1.0.onnx", "voices-v1.0.bin")
    except Exception as e:
        print(f"Error loading model: {e}")
        sys.exit(1)

    # Read text from stdin (piped input)
    try:
        text = sys.stdin.read().strip()
    except Exception:
        text = ""

    if not text:
        print("No text received.")
        return

    print(f"🗣️ Speaking: {text[:50]}...")

    # Generate audio
    # Voice options: 
    # 'af_sky' (American Female - Default)
    # 'af_bella', 'af_nicole', 'af_sarah'
    # 'am_michael', 'am_adam' (American Male)
    # 'bf_emma', 'bf_isabella' (British Female)
    # 'bm_george', 'bm_lewis' (British Male)
    try:
        samples, sample_rate = kokoro.create(
            text,
            voice="af_sky",
            speed=1.0,
            lang="en-us"
        )

        # Get default device sample rate
        device_info = sd.query_devices(kind='output')
        target_rate = int(device_info['default_samplerate'])
        original_rate = int(sample_rate)

        # Resample if needed
        if original_rate != target_rate:
            num_samples = int(len(samples) * target_rate / original_rate)
            samples = signal.resample(samples, num_samples)
            sample_rate = target_rate

        # Play audio
        sd.play(samples, samplerate=sample_rate, blocking=True)
    except Exception as e:
        print(f"Error generating/playing audio: {e}")

if __name__ == "__main__":
    main()
EOF

# 7. Final Instructions
SHORTCUT_CMD="sh -c \"cd $INSTALL_DIR && wl-paste --primary | uv run python speak.py\""

echo ""
echo "✅ Installation Complete!"
echo "-------------------------------------------------------"
echo "To create your keyboard shortcut in KDE Plasma:"
echo "1. Go to System Settings > Shortcuts > Add New > Command"
echo "2. Name: Read Selection (Kokoro)"
echo "3. Command: Copy the line below exactly:"
echo ""
echo "$SHORTCUT_CMD"
echo ""
echo "-------------------------------------------------------"
echo "🎉 Tip: To test it now, copy some text and run:"
echo "   cd $INSTALL_DIR && echo \"Kokoro installation is successful.\" | uv run python speak.py"
