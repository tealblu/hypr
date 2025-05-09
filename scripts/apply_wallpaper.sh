#!/bin/bash
# apply_wallpaper.sh - Applies a wallpaper to hyprpaper and pywal

# Configuration
CACHE_DIR="$HOME/.cache/wal"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
SELECTED_WALLPAPER_PATH="$CACHE_DIR/selected_wallpaper.txt"
LOG_FILE="$CACHE_DIR/apply_wallpaper.log"

# Function to apply wallpaper
apply_wallpaper() {
    local wallpaper="$1"
    
    # Ensure the wallpaper exists
    if [[ ! -f $wallpaper ]]; then
        echo "Wallpaper not found: $wallpaper" >> "$LOG_FILE"
        return 1
    fi
    
    echo "Applying wallpaper: $wallpaper" >> "$LOG_FILE"

	sleep 1

    # Restart hyprpaper
    echo "Restarting hyprpaper..." >> "$LOG_FILE"
    monitor=(`hyprctl monitors | grep Monitor | awk '{print $2}'`)
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload $wallpaper
    for m in "${monitor[@]}"; do
        hyprctl hyprpaper wallpaper "$m,$wallpaper"
    done
    
    # Copy wallpaper to wal cache
    cp "$wallpaper" "$CACHE_DIR/wallpaper"
    
    # Save wallpaper path for reference
    echo "$wallpaper" >"$CACHE_DIR/wallpaper.txt"
    
    # Generate pywal theme
    echo "Generating pywal theme..." >> "$LOG_FILE"
    /sbin/wal -i "$wallpaper" >> "$LOG_FILE" 2>&1 &

    # Generate GTK theme
    echo "Generating GTK theme..." >> "$LOG_FILE"
    /usr/bin/wpg -s "$wallpaper" >> "$LOG_FILE" 2>&1
    
    # Apply to discord theme if pywal-discord is installed
    if command -v pywal-discord &>/dev/null; then
        echo "Updating Discord theme..." >> "$LOG_FILE"
        pywal-discord -p "$HOME/.config/vesktop/themes" >> "$LOG_FILE" 2>&1
    fi
    
    # Restart swaync
    if command -v swaync &>/dev/null; then
        echo "Restarting swaync..." >> "$LOG_FILE"
        killall swaync 2>/dev/null || true
        hyprctl dispatch exec swaync
    fi
    
    echo "Wallpaper applied successfully!" >> "$LOG_FILE"
    return 0
}

# Main execution
main() {
    # Create log file with timestamp header
    echo "=== Wallpaper Application Log ($(date '+%F_%H:%M:%S')) ===" > "$LOG_FILE"
    
    # Check if a wallpaper path was provided as an argument
    if [[ $# -eq 1 ]]; then
        wallpaper="$1"
    # Otherwise read from the selected wallpaper file
    elif [[ -f $SELECTED_WALLPAPER_PATH ]]; then
        wallpaper=$(cat "$SELECTED_WALLPAPER_PATH")
    else
        echo "No wallpaper specified and no selection found" >> "$LOG_FILE"
        return 1
    fi
    
    apply_wallpaper "$wallpaper"
}

main "$@"