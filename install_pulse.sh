#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Install Pulse-Active on any Linux distribution.
set -euo pipefail

REPO_URL="https://github.com/corral1976/Pulse.git"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

METHOD="auto"     # auto | deb | generic
SOURCE="auto"     # auto | local | remote
PREFIX="/usr/local"

usage() {
    cat <<'USAGE'
Usage: bash install_pulse.sh [OPTIONS]

Install method (default: .deb on Debian/Ubuntu/Mint and derivatives, otherwise generic):
  --deb            Build and install a .deb package (Debian family only)
  --generic        Plain file install with make (any distribution)
  --user           Generic install for the current user only (~/.local, no root needed)
  --prefix DIR     Generic install under DIR instead of /usr/local

Source (default: this folder if it contains the project, otherwise GitHub):
  --local          Use the folder that contains this script
  --remote         Clone the latest version from GitHub

  -h, --help       Show this help
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --deb)     METHOD="deb" ;;
        --generic) METHOD="generic" ;;
        --user)    METHOD="generic"; PREFIX="$HOME/.local" ;;
        --prefix)
            [ $# -ge 2 ] || { echo "Error: --prefix needs a directory" >&2; exit 1; }
            METHOD="generic"; PREFIX="$2"; shift ;;
        --local)   SOURCE="local" ;;
        --remote)  SOURCE="remote" ;;
        -h|--help) usage; exit 0 ;;
        *)         echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
done

require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: '$1' is required but not installed." >&2
        [ -n "${2:-}" ] && echo "       $2" >&2
        exit 1
    fi
}

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        require sudo "Run this script as root, or install sudo."
        sudo "$@"
    fi
}

# --- choose the install method ---
if [ "$METHOD" = "auto" ]; then
    if command -v dpkg-deb >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
        METHOD="deb"
    else
        METHOD="generic"
    fi
fi
if [ "$METHOD" = "deb" ]; then
    require dpkg-deb "The .deb method only works on Debian-family systems. Use --generic instead."
else
    require make "Install it with your package manager (e.g. 'sudo dnf install make' or 'sudo pacman -S make')."
fi

# --- choose the source ---
if [ "$SOURCE" = "auto" ]; then
    if [ -f "$SRC_DIR/src/pulse" ] && [ -f "$SRC_DIR/Makefile" ]; then
        SOURCE="local"
    else
        SOURCE="remote"
    fi
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/pulse-install.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT
BUILD_DIR="$WORKDIR/pulse"

if [ "$SOURCE" = "local" ]; then
    if [ ! -f "$SRC_DIR/src/pulse" ] || [ ! -f "$SRC_DIR/Makefile" ]; then
        echo "Error: src/pulse and Makefile not found next to this script." >&2
        echo "Place the script in the project root, or use --remote to download from GitHub." >&2
        exit 1
    fi
    echo "=== Using local copy: $SRC_DIR ==="
    mkdir -p "$BUILD_DIR"
    cp -a "$SRC_DIR"/. "$BUILD_DIR"/
    rm -rf "$BUILD_DIR/.git"
    rm -f "$BUILD_DIR"/*.deb
else
    require git "Install it with your package manager, or download the repository as a zip instead."
    echo "=== Cloning the latest version from GitHub ==="
    git clone --depth 1 "$REPO_URL" "$BUILD_DIR"
fi

cd "$BUILD_DIR"

if [ "$METHOD" = "deb" ]; then
    echo "=== Building the .deb package ==="
    bash BUILD_DEB.sh

    DEB_FILE="$(find . -maxdepth 1 -name 'pulse-active_*_all.deb' -print -quit)"
    if [ -z "$DEB_FILE" ]; then
        echo "Error: the .deb file was not produced." >&2
        exit 1
    fi

    echo "=== Installing ${DEB_FILE#./} ==="
    as_root apt-get install "$PWD/${DEB_FILE#./}"

    echo "=== Verification ==="
    dpkg -s pulse-active | grep -E '^(Package|Status|Version):'
    dpkg -L pulse-active | grep -E 'bin/|icons|applications'
else
    echo "=== Installing under $PREFIX ==="
    # Use sudo only if the target is not writable by the current user.
    target="$PREFIX"
    while [ ! -e "$target" ]; do target="$(dirname "$target")"; done
    if [ -w "$target" ]; then
        make install PREFIX="$PREFIX"
    else
        as_root make install PREFIX="$PREFIX"
    fi

    echo "=== Verification ==="
fi

if command -v pulse >/dev/null 2>&1; then
    pulse --version
else
    "$PREFIX/bin/pulse" --version 2>/dev/null || true
    echo "Note: 'pulse' is not in your PATH yet. For a per-user install add this to ~/.bashrc:" >&2
    echo "      export PATH=\"$PREFIX/bin:\$PATH\"" >&2
fi
