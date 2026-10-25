#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Remove Pulse-Active, however it was installed (.deb, /usr/local or ~/.local),
# and check that its files are gone.
#
# Usage:
#   bash uninstall_pulse.sh
set -euo pipefail

PKG="pulse-active"

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "Error: need root (or sudo) to remove system files." >&2
        exit 1
    fi
}

# rm that escalates only when the file is not removable by the current user
remove_path() {
    local path="$1" parent
    [ -e "$path" ] || [ -L "$path" ] || return 0
    parent="$(dirname "$path")"
    if [ -w "$parent" ]; then
        rm -rf "$path"
    else
        as_root rm -rf "$path"
    fi
}

echo "=== Removing $PKG ==="

# 1) .deb installation
if command -v dpkg >/dev/null 2>&1 && dpkg -s "$PKG" >/dev/null 2>&1; then
    as_root dpkg --purge "$PKG"
    if dpkg -s "$PKG" >/dev/null 2>&1; then
        echo "WARNING: $PKG is still registered in dpkg"
    else
        echo "OK: $PKG is no longer registered in dpkg"
    fi
fi

# 2) files installed with 'make install' / install_pulse.sh --generic / --user
PREFIXES=("/usr/local" "$HOME/.local")
for prefix in "${PREFIXES[@]}"; do
    for f in "$prefix/bin/pulse" \
             "$prefix/share/applications/pulse-active.desktop" \
             "$prefix/share/icons/hicolor/scalable/apps/pulse.svg" \
             "$prefix/share/man/man1/pulse.1" \
             "$prefix/share/doc/pulse-active" \
             "$prefix/share/licenses/pulse-active"; do
        if [ -e "$f" ]; then
            remove_path "$f"
            echo "Removed $f"
        fi
    done
done

# 3) verify
leftovers=0
for f in /usr/bin/pulse \
         /usr/share/applications/pulse-active.desktop \
         /usr/share/icons/hicolor/scalable/apps/pulse.svg \
         /usr/share/doc/pulse-active \
         /usr/share/licenses/pulse-active \
         "${PREFIXES[@]/%//bin/pulse}"; do
    if [ -e "$f" ]; then
        echo "WARNING: $f still exists"
        leftovers=1
    else
        echo "OK: $f removed"
    fi
done

if command -v pulse >/dev/null 2>&1; then
    echo "NOTE: another 'pulse' is still in your PATH: $(command -v pulse)"
fi

[ "$leftovers" -eq 0 ] && echo "=== Uninstall complete ===" || { echo "=== Uninstall finished with warnings ==="; exit 1; }
