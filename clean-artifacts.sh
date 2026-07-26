#!/bin/bash
# remove build artifacts, keep dist/

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

rm -rf debian/vocal-plasma debian/.debhelper
rm -f debian/files debian/*.substvars debian/*.log debian/debhelper-build-stamp
rm -rf kokoro_tts.egg-info
find . -type d -name __pycache__ -not -path './.venv/*' -exec rm -rf {} + 2>/dev/null || true

echo "clean"
