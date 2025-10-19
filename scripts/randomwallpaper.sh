#!/bin/bash

# Directory containing your wallpaper images
WALLPAPER_DIR="/home/indigo/.waypaper/images" 

# Output from pywal
HP_THEME_OUTPUT="/home/indigo/.cache/wal/colors-hyprpanel.json"

# Get a random image file from the directory
# This command lists all files in the directory, filters for common image extensions,
# shuffles them, and picks one.
RANDOM_PICTURE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

# Check if a picture was found
if [ -z "$RANDOM_PICTURE" ]; then
    echo "No image files found in $WALLPAPER_DIR"
    exit 1
fi

# wal -i "$RANDOM_PICTURE" --cols16 -n
wpg -a "$RANDOM_PICTURE" -s "$RANDOM_PICTURE" -n
hyprpanel setWallpaper "$RANDOM_PICTURE"
hyprpanel useTheme "$HP_THEME_OUTPUT"
pywal-obsidianmd.sh /mnt/storage/Obsidian/Home
sleep 0.5
notify-send "Wallpaper changed: " $RANDOM_PICTURE -i "$RANDOM_PICTURE"