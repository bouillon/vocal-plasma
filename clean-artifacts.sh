#!/bin/bash
# Clean Debian package build artifacts

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Cleaning Debian Build Artifacts${NC}"
echo "=================================="
echo ""

# Debian build artifacts
echo "Removing debian build artifacts..."
rm -rf debian/vocal-plasma/
rm -rf debian/.debhelper/
rm -f debian/files
rm -f debian/*.substvars
rm -f debian/*.log
rm -f debian/debhelper-build-stamp

# Python build artifacts
echo "Removing Python build artifacts..."
rm -rf kokoro_tts.egg-info/
rm -rf build/bdist.*

# Temporary files
echo "Removing temporary files..."
rm -rf __pycache__/
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true

echo ""
echo -e "${GREEN}Cleanup complete!${NC}"
echo ""
echo "Kept:"
echo "  - build/output/ (final .deb packages)"
echo "  - Source files"
echo ""
