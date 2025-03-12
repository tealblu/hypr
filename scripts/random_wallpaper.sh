#!/bin/bash
# random_wallpaper.sh - Selects a random wallpaper from your wallpaper directory

# Configuration
WALLPAPER_DIR="$HOME/Pictures/bg"
CACHE_DIR="$HOME/.cache/wal"
OUTPUT_PATH="$CACHE_DIR/selected_wallpaper.txt"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Find a random image from the wallpaper directory
wallpaper=$(find "$WALLPAPER_DIR" -type f | sort -R --random-source=/dev/urandom | while read file; do
    # Check if the file is an image
    mimetype=$(file --mime-type -b "$file")
    if [[ "$mimetype" == image/* ]]; then
        echo "$file"
        break  # Use only the first valid image
    fi
done)

# Save the selected wallpaper path
echo "$wallpaper" > "$OUTPUT_PATH"
echo "$wallpaper" # Output for use in pipes or variable capture

# Success message
echo "Random wallpaper selected: $wallpaper" >&2