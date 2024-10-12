#!/bin/bash

preload_wallpaper() {

    monitor=""

    wallpaper_dir="$HOME/Pictures/bg"

    wallpapers=$(find "$wallpaper_dir" -type f | sort -R --random-source=/dev/urandom)

    for wallpaper in $wallpapers; do
        preload_string="preload = "$wallpaper"\n"
        wallpaper_string="wallpaper = $monitor, $wallpaper\n"
    done

    echo -en "$preload_string$wallpaper_string" > ~/.config/hypr/hyprpaper.conf

}

preload_wallpaper