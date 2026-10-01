#!/bin/bash
export PATH="$HOME/.local/bin:$PATH"

run_if_exists() {
    if command -v "$1" >/dev/null 2>&1; then
        "$@"
    else
        echo "Skip: Command $1 not found."
    fi
}

SELECTED_WALLPAPER=$1
RELOAD_APPS=$2
WALLPAPER_DIR="$HOME/.config/wallpapers"
WP_PATH=$("$HOME/.config/eww/scripts/resolve-wallpaper.sh" "$SELECTED_WALLPAPER" "$WALLPAPER_DIR") || {
    echo "Error: Wallpaper not found: $SELECTED_WALLPAPER"
    exit 1
}

if ! pgrep -x awww-daemon >/dev/null && ! pgrep -x awww >/dev/null; then
    awww-daemon >/dev/null 2>&1 &
    sleep 0.3
fi
# Fade at the panel refresh rate, and wait until it finishes.
# Generating colors during the fade drops frames.
awww img "$WP_PATH" \
    --resize crop \
    --filter Lanczos3 \
    --transition-type fade \
    --transition-duration 1.8 \
    --transition-fps 120 \
    --transition-bezier 0.42,0,0.58,1
printf '%s\n' "$WP_PATH" > "$HOME/.config/wallpapers/.current"

LOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
if [ -f "$LOCK_CONFIG" ]; then
    sed -i "s|^    path = .*|    path = $WP_PATH|" "$LOCK_CONFIG"
fi

# Eww applies new colours by building a replacement window and dropping the old
# one, which would otherwise replay the layer slide animation and make the bar and
# the control center jump around. Hold the layer animation off across the swap so
# they repaint in place. The current settings are read back from Hyprland rather
# than hardcoded, so hyprland.lua stays the only place they are defined.
LEAF_STATE=""
MAIN_EWW_PID=$(pgrep -f 'eww daemon$' | head -1)
# Address of the first layer surface this instance owns. It changes when eww
# swaps a window out, which is what tells us the restyle has landed.
eww_layer_addr() {
    [ -n "$MAIN_EWW_PID" ] || return 0
    hyprctl layers 2>/dev/null | grep "pid: $MAIN_EWW_PID" | head -1 |
        sed 's/.*Layer \([0-9a-f]*\):.*/\1/'
}
read_layer_anim() {
    hyprctl animations 2>/dev/null | python3 -c '
import sys, re
want = {"layersIn", "layersOut"}
cur, out = None, []
for line in sys.stdin:
    line = line.strip()
    if line.startswith("name: "):
        cur = line[6:]
        vals = {}
    elif cur in want and ": " in line:
        k, v = line.split(": ", 1)
        vals[k] = v
        if k == "style":
            out.append("{leaf=\"%s\", enabled=%s, speed=%s, bezier=\"%s\", style=\"%s\"}" % (
                cur, "true" if vals.get("enabled") == "1" else "false",
                vals.get("speed", "1"), vals.get("bezier") or "default", vals.get("style") or ""))
print(";".join(out))'
}
restore_layer_anim() {
    [ -n "$LEAF_STATE" ] || return 0
    local lua=""
    local IFS=';'
    for spec in $LEAF_STATE; do lua="$lua hl.animation($spec)"; done
    hyprctl eval "$lua" >/dev/null 2>&1
    LEAF_STATE=""
}
trap restore_layer_anim EXIT

ADDR_BEFORE=""
if [ -n "$(eww active-windows 2>/dev/null)" ]; then
    ADDR_BEFORE=$(eww_layer_addr)
    LEAF_STATE=$(read_layer_anim)
    hyprctl eval 'hl.animation({ leaf = "layersIn", enabled = false }) hl.animation({ leaf = "layersOut", enabled = false })' >/dev/null 2>&1
fi

mkdir -p "$HOME/.cache/matugen"
run_if_exists matugen image -m dark --source-color-index 0 "$WP_PATH"

if [ -n "$ADDR_BEFORE" ]; then
    # Wait for eww to put the replacement window up, then animate normally again.
    for _ in $(seq 1 25); do
        [ "$(eww_layer_addr)" != "$ADDR_BEFORE" ] && break
        sleep 0.1
    done
    sleep 0.2
    restore_layer_anim
fi

if [[ "$RELOAD_APPS" == "--generate-only" || "$RELOAD_APPS" == "-g" ]]; then
    echo "Generate only. Skipping app reload."
    exit 0
fi

# Matugen has just rewritten ~/.config/eww/colors.scss, which makes eww restyle
# the control center on its own.
#
# The picker is a separate eww instance, so it does not get rebuilt (that is what
# used to lose the scroll position). Its one themed colour is a variable, which
# repaints in place. While the picker is closed it is safe to reload it outright.
PICKER_DIR="$HOME/.config/eww-wallpaper"
if pgrep -f "eww.*$PICKER_DIR.*daemon" >/dev/null 2>&1; then
    NEW_BG=$(awk '/^\$background:/ {gsub(/[;]/,"",$2); print $2; exit}' "$HOME/.config/eww/colors.scss")
    [ -n "$NEW_BG" ] && eww -c "$PICKER_DIR" update panel-bg="$NEW_BG" >/dev/null 2>&1
    if ! eww -c "$PICKER_DIR" active-windows 2>/dev/null | grep -qw wallpaper; then
        eww -c "$PICKER_DIR" reload >/dev/null 2>&1
    fi
fi

if command -v makoctl >/dev/null 2>&1; then
    makoctl reload >/dev/null 2>&1 || true
fi

"$HOME/.config/eww/scripts/notify.sh" Wallpaper "Wallpaper" "$SELECTED_WALLPAPER" "$WP_PATH"

for SOCKET in /tmp/kitty-*; do
    if [ -S "$SOCKET" ]; then
        run_if_exists kitty @ --to "unix:$SOCKET" set-colors -a -c ~/.config/kitty/kitty-colors.conf
    fi
done

for sock in /tmp/nvim*; do
    if [ -S "$sock" ]; then
        run_if_exists nvim --server "$sock" --remote-send "<cmd>colorscheme lush-colors<CR>"
    fi
done
