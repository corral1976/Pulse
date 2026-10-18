#!/bin/bash

set -e

PACKAGE_NAME="pulse-active"
VERSION="1.0.0"
ARCHITECTURE="all"
DEBIAN_DIR="debian"
OUTPUT_FILE="${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"

echo "Building ${PACKAGE_NAME} version ${VERSION}..."

if [ ! -d "$DEBIAN_DIR" ]; then
    echo "Error: $DEBIAN_DIR directory not found!"
    exit 1
fi

echo "Checking package structure..."
if [ ! -f "$DEBIAN_DIR/DEBIAN/control" ]; then
    echo "Error: control file not found!"
    exit 1
fi

if [ ! -f "$DEBIAN_DIR/usr/bin/pulse" ]; then
    echo "Error: pulse executable not found!"
    exit 1
fi

if [ ! -f "$DEBIAN_DIR/usr/share/icons/hicolor/scalable/apps/pulse.svg" ]; then
    echo "Error: icon not found at usr/share/icons/hicolor/scalable/apps/pulse.svg!"
    exit 1
fi

INSTALLED_SIZE=$(du -sk "$DEBIAN_DIR" | cut -f1)

sed -i "s/^Installed-Size:.*/Installed-Size: $INSTALLED_SIZE/" "$DEBIAN_DIR/DEBIAN/control" || true

echo "Setting permissions..."
find "$DEBIAN_DIR" -type d -exec chmod 755 {} \;
find "$DEBIAN_DIR" -type f ! -path "*/DEBIAN/*" -exec chmod 644 {} \;
chmod 755 "$DEBIAN_DIR/usr/bin/pulse"
chmod 755 "$DEBIAN_DIR/DEBIAN/postinst" 2>/dev/null || true
chmod 755 "$DEBIAN_DIR/DEBIAN/prerm" 2>/dev/null || true
chmod 755 "$DEBIAN_DIR/DEBIAN/postrm" 2>/dev/null || true

echo "Building package..."
dpkg-deb --build --root-owner-group "$DEBIAN_DIR" "$OUTPUT_FILE"

if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(stat -c %s "$OUTPUT_FILE" | numfmt --to=iec)
    echo "Package built successfully: $OUTPUT_FILE ($SIZE)"
    echo ""
    echo "Package info:"
    dpkg -I "$OUTPUT_FILE"
    echo ""
    echo "To install: sudo dpkg -i $OUTPUT_FILE"
    echo "To remove: sudo dpkg -r $PACKAGE_NAME"
else
    echo "Error: Package build failed!"
    exit 1
fi
