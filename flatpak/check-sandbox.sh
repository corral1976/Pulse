#!/bin/bash
APP=io.gitlab.corral1976.PulseActive
flatpak run --command=bash "$APP" -c '
for c in awk grep sed cut df date stat uname stty sleep tput sensors lspci gdbus; do
    if command -v "$c" >/dev/null 2>&1; then echo "ok       $c"; else echo "FALTA    $c"; fi
done
echo; [ -d /run/host/usr ] && [ -r /run/host/os-release ] && echo "ok       /run/host" || echo "FALTA    /run/host"
echo; sensors 2>&1 | head -5
echo; lspci 2>&1 | grep -iE "vga|3d|display"
echo; pulse --once </dev/null'
