#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
# Super + C used to toggle the left bar. The bar is gone; this now opens
# the same overlay as Super + R.
exec "$HOME/.config/eww/scripts/toggle-control-center.sh"
