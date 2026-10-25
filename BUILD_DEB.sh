#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Build pulse-active_<version>_all.deb from the files in this repository.
# Everything is staged in a temporary directory; the working tree is not modified.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PACKAGE_NAME="pulse-active"
ARCHITECTURE="all"
VERSION="$(sed -n 's/^readonly SCRIPT_VERSION="\(.*\)"/\1/p' src/pulse)"
OUTPUT_FILE="${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"

if [ -z "$VERSION" ]; then
    echo "Error: could not read SCRIPT_VERSION from src/pulse" >&2
    exit 1
fi

command -v dpkg-deb >/dev/null 2>&1 || { echo "Error: dpkg-deb is required (Debian/Ubuntu and derivatives)." >&2; exit 1; }

echo "Building ${PACKAGE_NAME} version ${VERSION}..."

echo "Checking sources..."
for f in src/pulse man/pulse.1 data/pulse.svg data/pulse-active.desktop LICENSE README.md \
         packaging/debian/control packaging/debian/copyright packaging/debian/changelog \
         packaging/debian/postinst packaging/debian/postrm; do
    if [ ! -f "$f" ]; then
        echo "Error: $f not found!" >&2
        exit 1
    fi
done

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/pulse-deb.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

echo "Staging files..."
install -Dm755 src/pulse                      "$STAGE/usr/bin/pulse"
install -Dm644 data/pulse-active.desktop      "$STAGE/usr/share/applications/pulse-active.desktop"
install -Dm644 data/pulse.svg                 "$STAGE/usr/share/icons/hicolor/scalable/apps/pulse.svg"
install -Dm644 README.md                      "$STAGE/usr/share/doc/${PACKAGE_NAME}/README.md"
install -d -m755 "$STAGE/usr/share/man/man1"
gzip -9n -c man/pulse.1 > "$STAGE/usr/share/man/man1/pulse.1.gz"
chmod 644 "$STAGE/usr/share/man/man1/pulse.1.gz"
install -Dm644 packaging/debian/copyright     "$STAGE/usr/share/doc/${PACKAGE_NAME}/copyright"
gzip -9n -c packaging/debian/changelog > "$STAGE/usr/share/doc/${PACKAGE_NAME}/changelog.gz"
chmod 644 "$STAGE/usr/share/doc/${PACKAGE_NAME}/changelog.gz"

INSTALLED_SIZE="$(du -sk "$STAGE" | cut -f1)"

install -d -m755 "$STAGE/DEBIAN"
sed -e "s/@VERSION@/${VERSION}/" -e "s/@SIZE@/${INSTALLED_SIZE}/" \
    packaging/debian/control > "$STAGE/DEBIAN/control"
(cd "$STAGE" && find usr -type f -print0 | sort -z | xargs -0 md5sum > DEBIAN/md5sums)
install -m755 packaging/debian/postinst "$STAGE/DEBIAN/postinst"
install -m755 packaging/debian/postrm   "$STAGE/DEBIAN/postrm"

find "$STAGE" -type d -exec chmod 755 {} +

echo "Building package..."
dpkg-deb --build --root-owner-group "$STAGE" "$OUTPUT_FILE"

SIZE="$(stat -c %s "$OUTPUT_FILE" | numfmt --to=iec 2>/dev/null || stat -c %s "$OUTPUT_FILE")"
echo "Package built successfully: $OUTPUT_FILE ($SIZE)"
echo ""
echo "Package info:"
dpkg -I "$OUTPUT_FILE"
echo ""
echo "To install: sudo apt install ./$OUTPUT_FILE"
echo "To remove:  sudo apt remove $PACKAGE_NAME"
