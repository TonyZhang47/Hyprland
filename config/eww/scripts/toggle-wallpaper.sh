#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
# Open or close the wallpaper picker. Picking one also regenerates the theme.
# Bound to SUPER + G in ~/.config/hypr/hyprland.lua.
#
# The picker is its own eww instance so that recoloring the control center cannot
# rebuild this window and send the list back to the top.
PICKER_DIR="$HOME/.config/eww-wallpaper"

if eww -c "$PICKER_DIR" active-windows 2>/dev/null | grep -qw wallpaper; then
    eww -c "$PICKER_DIR" close wallpaper
else
    # Reload first so the picker opens with the current palette.
    eww -c "$PICKER_DIR" reload >/dev/null 2>&1
    eww -c "$PICKER_DIR" open wallpaper
fi
