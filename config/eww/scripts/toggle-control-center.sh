#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
# Toggle the dashboard overlay (clock, weather, apps, music, stats).
# SUPER + C toggles the dashboard overlay.

if eww active-windows 2>/dev/null | grep -qw control-center; then
    eww close control-center
else
    eww open control-center
fi
