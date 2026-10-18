#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Build and install Pulse-Active as a .deb package.
#
# Usage:
#   bash install_pulse.sh            Clone the latest version from GitLab, build and install it
#   bash install_pulse.sh --local    Build and install from the folder containing this script
#                                    (handy to test changes you have not pushed yet)
#   bash install_pulse.sh --help     Show this help

set -euo pipefail

REPO_URL="https://gitlab.com/corral1976/pulse.git"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="git"

usage() {
    sed -n '4,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
    case "$arg" in
        --local)   MODE="local" ;;
        -h|--help) usage; exit 0 ;;
        *)         echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: '$1' is required but not installed." >&2
        exit 1
    fi
}

require dpkg-deb
require sudo
if [ "$MODE" = "git" ]; then
    require git
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/pulse-install.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT
BUILD_DIR="$WORKDIR/pulse"

if [ "$MODE" = "local" ]; then
    echo "=== Using local copy: $SRC_DIR ==="
    if [ ! -d "$SRC_DIR/debian" ] || [ ! -f "$SRC_DIR/BUILD_DEB.sh" ]; then
        echo "Error: debian/ and BUILD_DEB.sh not found next to this script." >&2
        echo "Place the script in the project root, or run it without --local to use GitLab." >&2
        exit 1
    fi
    mkdir -p "$BUILD_DIR"
    cp -a "$SRC_DIR"/. "$BUILD_DIR"/
    rm -rf "$BUILD_DIR/.git"
    rm -f "$BUILD_DIR"/*.deb
else
    echo "=== Cloning the latest version from GitLab ==="
    git clone --depth 1 "$REPO_URL" "$BUILD_DIR"
fi

cd "$BUILD_DIR"

if [ ! -f debian/usr/share/icons/hicolor/scalable/apps/pulse.svg ]; then
    echo "Warning: icon not found in hicolor/scalable/apps/; the launcher may not show it." >&2
fi

echo "=== Building the .deb package ==="
bash BUILD_DEB.sh

DEB_FILE="$(find . -maxdepth 1 -name 'pulse-active_*_all.deb' -print -quit)"
if [ -z "$DEB_FILE" ]; then
    echo "Error: the .deb file was not produced." >&2
    exit 1
fi

echo "=== Installing ${DEB_FILE#./} ==="
sudo dpkg -i "$DEB_FILE"

echo "=== Verification ==="
dpkg -s pulse-active | grep -E '^(Package|Status|Version):'
dpkg -L pulse-active | grep -E 'icons|applications'
pulse --version
