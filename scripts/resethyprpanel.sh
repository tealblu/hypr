#!/usr/bin/env sh

killall dunst || true

wal -R || true

hyprctl dispatch exec hyprpanel quit &
hyprctl dispatch exec hyprpanel &

waypaper --restore &
