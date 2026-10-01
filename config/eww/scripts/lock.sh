#!/usr/bin/env bash
pidof hyprlock >/dev/null || hyprlock -c "$HOME/.config/hypr/hyprlock.conf"
