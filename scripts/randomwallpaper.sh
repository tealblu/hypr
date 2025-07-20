#!/bin/bash

# Directory containing your wallpaper images
WALLPAPER_DIR="/home/indigo/.waypaper/images" 

# Get a random image file from the directory
# This command lists all files in the directory, filters for common image extensions,
# shuffles them, and picks one.
RANDOM_PICTURE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

# Check if a picture was found
if [ -z "$RANDOM_PICTURE" ]; then
    echo "No image files found in $WALLPAPER_DIR"
    exit 1
fi

hyprpanel setWallpaper "$RANDOM_PICTURE"
notify-send "Wallpaper changed: " $RANDOM_PICTURE -i "$RANDOM_PICTURE"