#!/usr/bin/env bash
# Watch ~/.config/wallpapers and sync previews + theme caches on add/delete.
DIR="$HOME/.config/wallpapers"
SYNC="$HOME/.config/eww/scripts/sync-wallpapers.sh"
mkdir -p "$DIR"

"$SYNC" >/dev/null 2>&1 || true

command -v inotifywait >/dev/null 2>&1 || exit 0

inotifywait -m -q \
    -e close_write,moved_to,delete,moved_from,create \
    --format '%e %f' \
    "$DIR" |
while read -r events name; do
    case "$name" in
        preview-*|.current|.*|"") continue ;;
    esac
    sleep 0.35
    "$SYNC" >/dev/null 2>&1 || true
done
