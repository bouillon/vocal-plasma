#!/bin/bash
# kokoro-venv-setup - create/repair /opt/kokoro-tts/.venv
# order: imports ok -> relink to the python of lib/pythonX.Y -> rebuild

set -uo pipefail

PREFIX="${KOKORO_PREFIX:-/opt/kokoro-tts}"
VENV="$PREFIX/.venv"
IMPORT_CHECK="import numpy, scipy, soundfile, sounddevice, kokoro_onnx, piper"

log() { echo "kokoro-venv-setup: $*"; }
err() { echo "kokoro-venv-setup: $*" >&2; }

# X.Y of lib/pythonX.Y
venv_lib_version() {
    local dir
    for dir in "$VENV"/lib/python3.*; do
        [ -d "$dir" ] || continue
        echo "${dir##*/python}"
        return 0
    done
    return 1
}

venv_run_version() {
    "$VENV/bin/python" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null
}

venv_imports_ok() {
    [ -x "$VENV/bin/python" ] || return 1
    "$VENV/bin/python" -c "$IMPORT_CHECK" >/dev/null 2>&1
}

# $KOKORO_PYTHON, default python3, then /usr/bin/python3.N newest first
candidate_interpreters() {
    local seen=" " py real
    for py in "${KOKORO_PYTHON:-}" "$(command -v python3 2>/dev/null)" \
              $(ls -1 /usr/bin/python3.[0-9]* 2>/dev/null \
                | grep -E '/python3\.[0-9]+$' | sort -t. -k2,2nr); do
        [ -n "$py" ] || continue
        real=$(readlink -f "$py" 2>/dev/null) || continue
        [ -x "$real" ] || continue
        case "$seen" in *" $real "*) continue ;; esac
        seen="$seen$real "
        echo "$real"
    done
}

# point bin/python back at the python of lib/pythonX.Y - no network
relink_venv() {
    local lib target full
    lib=$(venv_lib_version) || return 1
    target="/usr/bin/python$lib"
    [ -x "$target" ] || return 1

    log "relink -> $target"
    ln -sfn "$target" "$VENV/bin/python3" || return 1
    ln -sfn python3 "$VENV/bin/python" || return 1
    ln -sfn python3 "$VENV/bin/python$lib" || return 1

    full=$("$target" -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' 2>/dev/null)
    if [ -n "$full" ] && [ -f "$VENV/pyvenv.cfg" ]; then
        sed -i -e "s|^home = .*|home = /usr/bin|" \
               -e "s|^version = .*|version = $full|" \
               -e "s|^executable = .*|executable = $target|" "$VENV/pyvenv.cfg"
    fi

    venv_imports_ok
}

# install new/missing deps into the existing venv - no full rebuild
sync_venv() {
    [ -x "$VENV/bin/pip" ] || return 1
    log "sync deps into existing venv"
    "$VENV/bin/pip" install -e "$PREFIX" \
        || "$VENV/bin/pip" install --ignore-requires-python -e "$PREFIX" \
        || return 1
    venv_imports_ok
}

# fresh venv; old one stays until the new one imports
rebuild_venv() {
    local py new ver
    new="$PREFIX/.venv.new.$$"

    for py in $(candidate_interpreters); do
        ver=$("$py" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null)
        log "build with $py"
        rm -rf "$new"

        "$py" -m venv "$new" >/dev/null 2>&1 || { err "  no venv module"; continue; }
        "$new/bin/pip" install --upgrade pip setuptools wheel || err "  pip upgrade failed, continuing"
        # second try ignores Requires-Python caps; import check below still gates
        "$new/bin/pip" install -e "$PREFIX" \
            || "$new/bin/pip" install --ignore-requires-python -e "$PREFIX" \
            || { err "  deps failed on $ver"; rm -rf "$new"; continue; }
        "$new/bin/python" -c "$IMPORT_CHECK" >/dev/null 2>&1 || { err "  imports failed on $ver"; rm -rf "$new"; continue; }

        rm -rf "$VENV.old"
        [ -e "$VENV" ] && mv "$VENV" "$VENV.old"
        mv "$new" "$VENV"
        rm -rf "$VENV.old"
        log "rebuilt on python $ver"
        return 0
    done

    rm -rf "$new"
    return 1
}

if [ ! -w "$PREFIX" ]; then
    err "no write access to $PREFIX - run as root"
    exit 1
fi
if [ ! -f "$PREFIX/pyproject.toml" ]; then
    err "$PREFIX/pyproject.toml missing - package not installed?"
    exit 1
fi

rm -rf "$PREFIX"/.venv.new.*

if venv_imports_ok; then
    log "ok (python $(venv_run_version))"
    exit 0
fi

if [ -d "$VENV" ]; then
    if relink_venv; then
        log "repaired offline (python $(venv_run_version))"
        exit 0
    fi
    if sync_venv; then
        log "deps synced (python $(venv_run_version))"
        exit 0
    fi
fi

rebuild_venv && exit 0

err "failed - check network, then rerun: kokoro-venv-setup"
exit 1
