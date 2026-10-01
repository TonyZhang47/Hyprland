#!/usr/bin/env bash
# Print the full path of a wallpaper by its stem (no extension).
NAME="$1"
DIR="${2:-$HOME/.config/wallpapers}"
[ -n "$NAME" ] || exit 1
for ext in jpg jpeg png webp JPG JPEG PNG WEBP; do
    candidate="$DIR/$NAME.$ext"
    if [ -f "$candidate" ]; then
        printf '%s\n' "$candidate"
        exit 0
    fi
done
exit 1
