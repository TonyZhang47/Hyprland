#!/usr/bin/env bash
# Pick a wallpaper and recolor the whole rice (eww, kitty, rofi, nvim).
# Super + Shift + T runs this.
export PATH="$HOME/.local/bin:$PATH"

WALLPAPER_DIR="$HOME/.config/wallpapers"
CURRENT=""
if [ -f "$WALLPAPER_DIR/.current" ]; then
    CURRENT=$(basename "$(head -n 1 "$WALLPAPER_DIR/.current")")
    CURRENT="${CURRENT%.*}"
fi

mapfile -t WALLPAPERS < <(
    find "$WALLPAPER_DIR" -maxdepth 1 \( \
        -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
    \) ! -name 'preview-*' -printf '%f\n' \
        | sed -E 's/\.[^.]+$//' | sort -V
)

[ ${#WALLPAPERS[@]} -eq 0 ] && exit 1

LIST=""
for name in "${WALLPAPERS[@]}"; do
    if [ "$name" = "$CURRENT" ]; then
        LIST+="󰸉  $name (current)"$'\n'
    else
        LIST+="󰸉  $name"$'\n'
    fi
done

CHOSEN=$(printf '%s' "$LIST" | rofi -dmenu -i -p "Theme:" | awk '{print $2}')
[ -z "$CHOSEN" ] && exit 0

"$HOME/.config/eww/scripts/update-color.sh" "$CHOSEN"
