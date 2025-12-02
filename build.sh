#!/bin/bash
# Build script for Kokoro TTS Debian package
# Builds the package to the ./build directory

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${BUILD_DIR}/output"

echo -e "${YELLOW}Vocal Plasma Debian Package Builder${NC}"
echo "========================================"
echo "Project directory: $PROJECT_DIR"
echo "Build directory: $BUILD_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Clean old builds
echo -e "${YELLOW}Cleaning old build artifacts...${NC}"
rm -rf "${BUILD_DIR:?}"/vocal-plasma* "${BUILD_DIR:?}"/*.deb "${BUILD_DIR:?}"/*.changes "${BUILD_DIR:?}"/*.buildinfo 2>/dev/null || true
rm -rf "${PROJECT_DIR}"/debian/vocal-plasma 2>/dev/null || true

# Build the package into the build directory
echo -e "${YELLOW}Building package...${NC}"
cd "$PROJECT_DIR"
dpkg-buildpackage -us -uc -d

# Move build artifacts to output directory
echo -e "${YELLOW}Moving artifacts to output directory...${NC}"
mv -f "${PROJECT_DIR}"/../vocal-plasma_*.deb "$OUTPUT_DIR/" 2>/dev/null || true
mv -f "${PROJECT_DIR}"/../vocal-plasma_*.changes "$OUTPUT_DIR/" 2>/dev/null || true
mv -f "${PROJECT_DIR}"/../vocal-plasma_*.buildinfo "$OUTPUT_DIR/" 2>/dev/null || true

# Show build results
echo ""
echo -e "${GREEN}Build completed!${NC}"
echo ""
echo "Output files:"
ls -lh "$OUTPUT_DIR"/ | tail -n +2

echo ""
echo -e "${YELLOW}Installation instructions:${NC}"
echo "dpkg -r vocal-plasma              # (Optional) Remove old package"
echo "dpkg -i ${OUTPUT_DIR}/vocal-plasma_*.deb"
echo ""

# Also show the path for easy reference
echo -e "${YELLOW}Package location:${NC}"
echo "${OUTPUT_DIR}/"
