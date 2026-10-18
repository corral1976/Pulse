#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Remove the Pulse-Active package and check that its files are gone.
#
# Usage:
#   bash uninstall_pulse.sh

set -euo pipefail

PKG="pulse-active"

echo "=== Removing $PKG ==="
if dpkg -s "$PKG" >/dev/null 2>&1; then
    sudo dpkg --purge "$PKG"
else
    echo "$PKG is not installed; nothing to remove."
fi

if dpkg -s "$PKG" >/dev/null 2>&1; then
    echo "WARNING: $PKG is still registered in dpkg"
else
    echo "OK: $PKG is no longer registered in dpkg"
fi

for f in /usr/bin/pulse \
         /usr/share/applications/pulse-active.desktop \
         /usr/share/icons/hicolor/scalable/apps/pulse.svg \
         /usr/share/doc/pulse-active \
         /usr/share/licenses/pulse-active; do
    if [ -e "$f" ]; then
        echo "WARNING: $f still exists"
    else
        echo "OK: $f removed"
    fi
done

# Copies in the user's home are not owned by the package and are never touched here,
# but they take precedence over the system files and can show a stale icon or entry.
for f in "$HOME/.local/share/icons/pulse.svg" \
         "$HOME/.local/share/applications/pulse-active.desktop"; do
    if [ -e "$f" ]; then
        echo "NOTE: $f exists (not removed); it overrides the system version."
    fi
done

echo "=== Uninstall complete ==="
