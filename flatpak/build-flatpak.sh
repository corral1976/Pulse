#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

APP=io.gitlab.corral1976.PulseActive
if command -v flatpak-builder >/dev/null 2>&1; then
    FB=(flatpak-builder)
else
    FB=(flatpak run org.flatpak.Builder)
fi

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08

"${FB[@]}" --user --install --force-clean --install-deps-from=flathub \
    --repo=repo build-dir "$APP.yml"

if [ "${1:-}" = "--bundle" ]; then
    flatpak build-bundle repo "pulse-active-1.1.0.flatpak" "$APP"
    echo "Bundle: $(pwd)/pulse-active-1.1.0.flatpak"
fi

echo "Listo. Ejecuta: flatpak run $APP"
