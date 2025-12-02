#!/bin/bash
# Install Kokoro TTS model files to user directory

set -e

MODEL_FILE="kokoro-v1.0.onnx"
VOICES_FILE="voices-v1.0.bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if model files exist in current directory
if [ ! -f "$MODEL_FILE" ] || [ ! -f "$VOICES_FILE" ]; then
    echo -e "${RED}Error: Model files not found in current directory${NC}"
    echo "Required files:"
    echo "  - $MODEL_FILE"
    echo "  - $VOICES_FILE"
    echo ""
    echo "Please download the model files first."
    exit 1
fi

echo "Kokoro TTS Model Installation"
echo "=============================="
echo ""
echo "Choose installation location:"
echo "  1) ~/.local/share/kokoro-tts/ (Recommended)"
echo "  2) Custom directory in your home"
echo ""
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        INSTALL_DIR="$HOME/.local/share/kokoro-tts"
        ;;
    2)
        read -p "Enter custom directory path: " INSTALL_DIR
        # Expand ~ to home directory
        INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "Installing models to: ${GREEN}$INSTALL_DIR${NC}"

# Create directory
echo "Creating directory..."
mkdir -p "$INSTALL_DIR"

# Copy files
echo "Copying model files..."
cp -v "$MODEL_FILE" "$INSTALL_DIR/"
cp -v "$VOICES_FILE" "$INSTALL_DIR/"

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Models installed to: $INSTALL_DIR"
echo "Size:"
du -h "$INSTALL_DIR/$MODEL_FILE" "$INSTALL_DIR/$VOICES_FILE"
echo ""
echo "You can now use the 'speak' command:"
echo "  echo 'Hello world' | speak"
