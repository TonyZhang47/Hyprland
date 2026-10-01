#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
# SUPER + H toggles the settings popup.

if eww active-windows 2>/dev/null | grep -qw settings; then
    eww close settings
    exit 0
fi

payload="$("$HOME/.config/eww/scripts/get-user-settings.py")"
eww update "user-settings=${payload}" >/dev/null 2>&1 || true
eww open settings
