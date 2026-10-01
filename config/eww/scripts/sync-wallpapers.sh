#!/usr/bin/env bash
# Keep ~/.config/wallpapers in sync with Super+G and theme caches.
#   - New jpg/png/webp -> preview thumbnail + matugen palette cache
#   - Deleted wallpaper -> drop preview, drop cache; if it was current, switch
# Bound to a watcher on Hyprland start. Safe to run by hand.

set -euo pipefail
DIR="$HOME/.config/wallpapers"
CACHE="$HOME/.cache/matugen/wallpapers"
PICKER_DIR="$HOME/.config/eww-wallpaper"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-sync.lock"
mkdir -p "$DIR" "$CACHE"

ext_of() {
    local f="$1"
    echo "${f##*.}"
}

stem_of() {
    local base
    base=$(basename "$1")
    echo "${base%.*}"
}

is_wallpaper() {
    local base ext
    base=$(basename "$1")
    case "$base" in
        preview-*|.current|.*) return 1 ;;
    esac
    ext=$(echo "${base##*.}" | tr 'A-Z' 'a-z')
    case "$ext" in
        jpg|jpeg|png|webp) return 0 ;;
        *) return 1 ;;
    esac
}

source_for_stem() {
    local stem="$1" ext
    for ext in jpg jpeg png webp JPG JPEG PNG WEBP; do
        if [ -f "$DIR/$stem.$ext" ]; then
            printf '%s\n' "$DIR/$stem.$ext"
            return 0
        fi
    done
    return 1
}

make_preview() {
    local src="$1" stem dest
    stem=$(stem_of "$src")
    dest="$DIR/preview-${stem}.jpg"
    [ -f "$dest" ] && return 0
    command -v magick >/dev/null || return 0
    magick "$src" -resize '600x400^' -gravity center -extent 600x400 -quality 85 "$dest"
}

make_theme() {
    local src="$1" stem dest
    stem=$(stem_of "$src")
    dest="$CACHE/${stem}.json"
    [ -s "$dest" ] && return 0
    command -v matugen >/dev/null || return 0
    local tmp
    tmp=$(mktemp)
    if matugen image -m dark --source-color-index 0 --dry-run -q -j hex "$src" >"$tmp" 2>/dev/null \
        && python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$tmp"; then
        mv "$tmp" "$dest"
    else
        rm -f "$tmp"
    fi
}

list_stems() {
    shopt -s nullglob
    local f stem
    for f in "$DIR"/*; do
        [ -f "$f" ] || continue
        is_wallpaper "$f" || continue
        stem_of "$f"
    done | sort -Vu
}

refresh_picker() {
    export PATH="$HOME/.local/bin:$PATH"
    command -v eww >/dev/null || return 0
    local json
    json=$("$HOME/.config/eww/scripts/get-wallpapers.sh" 2>/dev/null) || return 0
    eww -c "$PICKER_DIR" update "wallpapers=${json}" >/dev/null 2>&1 || true
}

switch_if_current_missing() {
    local current=""
    if [ -f "$DIR/.current" ]; then
        current=$(head -n 1 "$DIR/.current")
    fi
    if [ -n "$current" ] && [ -f "$current" ]; then
        return 0
    fi
    local first
    first=$(list_stems | head -n 1)
    [ -n "$first" ] || return 0
    "$HOME/.config/eww/scripts/update-color.sh" "$first" >/dev/null 2>&1 || true
}

sync_one() {
    local src="$1"
    is_wallpaper "$src" || return 0
    [ -f "$src" ] || return 0
    make_preview "$src"
    make_theme "$src"
}

cleanup_orphans() {
    shopt -s nullglob
    local f stem
    for f in "$DIR"/preview-*.jpg; do
        stem=$(basename "$f")
        stem=${stem#preview-}
        stem=${stem%.jpg}
        if ! source_for_stem "$stem" >/dev/null; then
            rm -f "$f"
        fi
    done
    for f in "$CACHE"/*.json; do
        [ -e "$f" ] || continue
        stem=$(basename "$f" .json)
        if ! source_for_stem "$stem" >/dev/null; then
            rm -f "$f"
        fi
    done
}

exec 9>"$LOCK"
flock 9

if [ "${1:-}" = "--one" ] && [ -n "${2:-}" ]; then
    sync_one "$2"
    cleanup_orphans
    switch_if_current_missing
    refresh_picker
    exit 0
fi

shopt -s nullglob
for f in "$DIR"/*; do
    [ -f "$f" ] || continue
    sync_one "$f"
done
cleanup_orphans
switch_if_current_missing
refresh_picker
