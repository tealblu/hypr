#!/bin/bash

preload_wallpaper() {

    monitor=""
    wallpaper_dir="$HOME/Pictures/bg"
    hp_conf="$HOME/.config/hypr/hyprpaper.conf"

    # build hyprpaper.conf
    output_string=""
    output_string+="# --- hyprpaper autogen by indigo hartsell ---\n"
    output_string+="# random wallpaper from $wallpaper_dir\n"
    output_string+="\n"

    wallpapers=$(find "$wallpaper_dir" -type f | sort -R --random-source=/dev/urandom)
    for wallpaper in $wallpapers; do
        preload_string="preload = "$wallpaper"\n"
        wallpaper_string="wallpaper = $monitor, $wallpaper\n"
    done

    output_string+="$preload_string"
    output_string+="$wallpaper_string"

    echo -en "$output_string" > $hp_conf

}

preload_wallpaper