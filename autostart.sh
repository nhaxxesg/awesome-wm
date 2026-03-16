#!/bin/sh

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
AWESOME_DIR="$CONFIG_HOME/awesome"
WALLPAPER="$AWESOME_DIR/wallpaper.svg"

run_once() {
    process_name="$1"
    shift

    if ! pgrep -u "$USER" -x "$process_name" >/dev/null 2>&1; then
        "$@" >/dev/null 2>&1 &
    fi
}

run_once picom picom --config "$CONFIG_HOME/picom/picom.conf"
run_once lxpolkit lxpolkit
run_once dunst dunst

if command -v feh >/dev/null 2>&1 && [ -f "$WALLPAPER" ]; then
    feh --bg-fill "$WALLPAPER"
fi

xsetroot -cursor_name left_ptr
