#!/bin/bash

preload_wallpaper() {

    # config
    monitor=""
    wallpaper_dir="$HOME/Pictures/bg"
    hp_conf="$HOME/.config/hypr/hyprpaper.conf"

    # var
    NOW=$(date '+%F_%H:%M:%S')
    output_string=""

    # build hyprpaper.conf
    output_string+="# --- hyprpaper autogen by indigo hartsell ---\n"
    output_string+="# random wallpaper from $wallpaper_dir\n"
    output_string+="# ran $NOW\n"
    output_string+="\n"

    wallpapers=$(find "$wallpaper_dir" -type f | sort -R --random-source=/dev/urandom)
    for wallpaper in $wallpapers; do
        # Check if the file is an image
        mimetype=$(file --mime-type -b "$wallpaper")
        if [[ "$mimetype" == image/* ]]; then
            # Use quotes to ensure special characters are handled
            preload_string="preload = $wallpaper\n"
            wallpaper_string="wallpaper = $monitor, $wallpaper\n"
            output_string+=$preload_string
            output_string+=$wallpaper_string
            break  # Load only the first valid image
        fi
    done

    echo -en "$output_string" > "$hp_conf"

    # Output the wallpaper to be used in the parent shell
    echo "$wallpaper"
}

generate_theme() {
    wallpaper=$(preload_wallpaper)  # Get the wallpaper path from preload_wallpaper

    echo "Killing existing hyprpaper..."
    killall hyprpaper || true
    
    echo "Starting hyprpaper..."
    hyprctl dispatch exec hyprpaper

    # Run wal to generate colors
    wal -i "$wallpaper" &

    # Copy the wallpaper to ~/.cache/wal and ensure the file is called wallpaper
    cp "$wallpaper" "$HOME/.cache/wal/wallpaper"

    # (Optional) Restart any applications that depend on the theme
    echo "Restarting swaync..."
    killall swaync

    echo "Starting swaync..."
    swaync
}

#preload_wallpaper
generate_theme