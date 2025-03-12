#!/bin/bash
# apply_wallpaper.sh - Applies a wallpaper to hyprpaper and pywal

# Configuration
CACHE_DIR="$HOME/.cache/wal"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
SELECTED_WALLPAPER_PATH="$CACHE_DIR/selected_wallpaper.txt"

# Function to apply wallpaper
apply_wallpaper() {
    local wallpaper="$1"
    
    # Ensure the wallpaper exists
    if [[ ! -f "$wallpaper" ]]; then
        echo "Wallpaper not found: $wallpaper" >&2
        return 1
    fi
    
    echo "Applying wallpaper: $wallpaper" >&2
    
    # Update hyprpaper configuration file
    cat > "$HYPRPAPER_CONF" << EOF
# --- hyprpaper configuration ---
# Generated on $(date '+%F_%H:%M:%S')
# Wallpaper: $wallpaper

preload = $wallpaper
wallpaper = , $wallpaper
EOF
    
    # Restart hyprpaper
    echo "Restarting hyprpaper..." >&2
    killall hyprpaper 2>/dev/null || true
    hyprctl dispatch exec hyprpaper
    
    # Generate pywal theme
    echo "Generating pywal theme..." >&2
    wal -i "$wallpaper"
    
    # Copy wallpaper to wal cache
    cp "$wallpaper" "$CACHE_DIR/wallpaper"
    
    # Save wallpaper path for reference
    echo "$wallpaper" > "$CACHE_DIR/wallpaper.txt"
    
    # Apply to discord theme if pywal-discord is installed
    if command -v pywal-discord &>/dev/null; then
        echo "Updating Discord theme..." >&2
        pywal-discord -p "$HOME/.config/vesktop/themes"
    fi
    
    # Restart notification daemon
    echo "Restarting swaync..." >&2
    killall swaync 2>/dev/null || true
    swaync &
    
    echo "Wallpaper applied successfully!" >&2
    return 0
}

# Main execution
main() {
    # Check if a wallpaper path was provided as an argument
    if [[ $# -eq 1 ]]; then
        wallpaper="$1"
    # Otherwise read from the selected wallpaper file
    elif [[ -f "$SELECTED_WALLPAPER_PATH" ]]; then
        wallpaper=$(cat "$SELECTED_WALLPAPER_PATH")
    else
        echo "No wallpaper specified and no selection found" >&2
        return 1
    fi
    
    apply_wallpaper "$wallpaper"
}

main "$@"