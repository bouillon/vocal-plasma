#!/bin/bash
# speak - Kokoro TTS

export KOKORO_MODEL_PATH="/usr/share/kokoro-tts/kokoro-v1.0.onnx"
export KOKORO_VOICES_PATH="/usr/share/kokoro-tts/voices-v1.0.bin"
export PIPER_MODEL_PATH="/usr/share/kokoro-tts/ru_RU-irina-medium.onnx"

VENV="/opt/kokoro-tts/.venv"
SETUP=/usr/bin/kokoro-venv-setup

cd /opt/kokoro-tts || exit 1

# stale = bin/python minor != lib/pythonX.Y minor
venv_is_stale() {
    local libdir libver realpy realver
    for libdir in "$VENV"/lib/python3.*; do
        [ -d "$libdir" ] && libver="${libdir##*/python}" && break
    done
    [ -n "${libver:-}" ] || return 0

    realpy=$(readlink -f "$VENV/bin/python" 2>/dev/null)
    [ -n "$realpy" ] && [ -x "$realpy" ] || return 0
    realver="${realpy##*/python}"

    case "$realver" in
        3.*) [ "$libver" != "$realver" ] ;;
        *) return 1 ;;
    esac
}

repair_venv() {
    echo "speak: adapting venv..." >&2
    if [ "$(id -u)" = 0 ]; then
        "$SETUP" && return 0
    elif sudo -n true 2>/dev/null; then
        sudo -n "$SETUP" && return 0
    elif command -v pkexec >/dev/null && [ -n "${WAYLAND_DISPLAY:-${DISPLAY:-}}" ]; then
        pkexec "$SETUP" && return 0
    fi
    echo "speak: run: sudo kokoro-venv-setup" >&2
    return 1
}

if [ ! -d "$VENV" ] || venv_is_stale; then
    repair_venv || exit 1
fi

exec "$VENV/bin/python" -m kokoro_tts.cli "$@"
