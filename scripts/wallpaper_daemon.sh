#!/bin/bash
# wallpaper_daemon.sh - Monitors media players and switches wallpapers accordingly

# Configuration
SCRIPT_DIR="$HOME/.config/hypr/scripts"  # Hard-coded script directory
CONFIG_DIR="$HOME/.config/wallpaper-daemon"
ENABLED_FILE="$CONFIG_DIR/enabled"
CACHE_DIR="$HOME/.cache/wal"
CHECK_INTERVAL=5  # Check every 5 seconds

# Script paths - using the fixed script directory
RANDOM_WALLPAPER_SCRIPT="${SCRIPT_DIR}/random_wallpaper.sh"
SPOTIFY_WALLPAPER_SCRIPT="${SCRIPT_DIR}/spotify_wallpaper.sh"
APPLY_WALLPAPER_SCRIPT="${SCRIPT_DIR}/apply_wallpaper.sh"

# Create necessary directories
mkdir -p "$CONFIG_DIR"

# Initialize enabled state if it doesn't exist
if [[ ! -f "$ENABLED_FILE" ]]; then
    echo "true" > "$ENABLED_FILE"
fi

# Function to verify all scripts exist
check_scripts() {
    local missing=false
    
    if [[ ! -f "$RANDOM_WALLPAPER_SCRIPT" ]]; then
        echo "Error: Random wallpaper script not found at $RANDOM_WALLPAPER_SCRIPT" >&2
        missing=true
    fi
    
    if [[ ! -f "$SPOTIFY_WALLPAPER_SCRIPT" ]]; then
        echo "Error: Spotify wallpaper script not found at $SPOTIFY_WALLPAPER_SCRIPT" >&2
        missing=true
    fi
    
    if [[ ! -f "$APPLY_WALLPAPER_SCRIPT" ]]; then
        echo "Error: Apply wallpaper script not found at $APPLY_WALLPAPER_SCRIPT" >&2
        missing=true
    fi
    
    if $missing; then
        echo "Please ensure all required scripts are installed in $SCRIPT_DIR" >&2
        return 1
    fi
    
    # Make scripts executable
    chmod +x "$RANDOM_WALLPAPER_SCRIPT" "$SPOTIFY_WALLPAPER_SCRIPT" "$APPLY_WALLPAPER_SCRIPT"
    return 0
}

# Function to check if daemon is enabled
is_enabled() {
    if [[ "$(cat "$ENABLED_FILE")" == "true" ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}

# Function to toggle daemon enabled/disabled
toggle_daemon() {
    if is_enabled; then
        echo "false" > "$ENABLED_FILE"
        echo "Wallpaper daemon disabled"
    else
        echo "true" > "$ENABLED_FILE"
        echo "Wallpaper daemon enabled"
    fi
}

# Function to check if Spotify is playing
is_spotify_playing() {
    if playerctl --player=spotify status 2>/dev/null | grep -q "Playing"; then
        return 0  # True
    else
        return 1  # False
    fi
}

# Function to get current track info
get_current_track() {
    playerctl --player=spotify metadata --format "{{artist}} - {{title}}" 2>/dev/null || echo ""
}

# Function to apply random wallpaper
apply_random_wallpaper() {
    if [ "$1" != "force" ] && ! $USING_SPOTIFY; then
        return  # Already using random wallpaper, no need to change
    fi
    
    echo "Switching to random wallpaper"
    # Fallback to a direct wallpaper path if the script fails
    if ! "$RANDOM_WALLPAPER_SCRIPT" | "$APPLY_WALLPAPER_SCRIPT"; then
        if [ -d "$HOME/Pictures/bg" ]; then
            find "$HOME/Pictures/bg" -type f | grep -E '\.(jpg|png|jpeg)$' | shuf -n 1 | "$APPLY_WALLPAPER_SCRIPT"
        else
            echo "Failed to apply random wallpaper and no fallback directory found" >&2
        fi
    fi
    USING_SPOTIFY=false
}

# Function to apply Spotify wallpaper
apply_spotify_wallpaper() {
    echo "Switching to Spotify wallpaper"
    if ! "$SPOTIFY_WALLPAPER_SCRIPT" | "$APPLY_WALLPAPER_SCRIPT"; then
        echo "Failed to apply Spotify wallpaper, falling back to random" >&2
        apply_random_wallpaper "force"
        return
    fi
    USING_SPOTIFY=true
}

# Current state tracking
LAST_TRACK=""
USING_SPOTIFY=false

# Parse command line arguments
case "$1" in
    toggle)
        toggle_daemon
        exit 0
        ;;
    status)
        if is_enabled; then
            echo "Wallpaper daemon is enabled"
            echo "Using scripts:"
            echo "  Random: $RANDOM_WALLPAPER_SCRIPT"
            echo "  Spotify: $SPOTIFY_WALLPAPER_SCRIPT"
            echo "  Apply: $APPLY_WALLPAPER_SCRIPT"
        else
            echo "Wallpaper daemon is disabled"
        fi
        exit 0
        ;;
    start)
        echo "true" > "$ENABLED_FILE"
        echo "Wallpaper daemon enabled"
        ;;
    stop)
        echo "false" > "$ENABLED_FILE"
        echo "Wallpaper daemon disabled"
        ;;
    spotify)
        # Force switch to Spotify wallpaper
        check_scripts && apply_spotify_wallpaper
        exit 0
        ;;
    random)
        # Force switch to random wallpaper
        check_scripts && apply_random_wallpaper "force"
        exit 0
        ;;
    setup)
        echo "Setting up wallpaper daemon scripts..."
        # Make all scripts executable
        chmod +x "$RANDOM_WALLPAPER_SCRIPT" "$SPOTIFY_WALLPAPER_SCRIPT" "$APPLY_WALLPAPER_SCRIPT" "$SCRIPT_DIR/wallpaper_daemon.sh"
        echo "Scripts are ready to use in $SCRIPT_DIR"
        exit 0
        ;;
    *)
        # Continue to main loop for daemon mode
        ;;
esac

# Verify scripts exist before starting daemon
if ! check_scripts; then
    exit 1
fi

# Main loop
echo "Starting wallpaper daemon..."
# Apply initial random wallpaper
apply_random_wallpaper "force"

while true; do
    # Check if daemon is enabled
    if ! is_enabled; then
        sleep "$CHECK_INTERVAL"
        continue
    fi
    
    # Check Spotify status
    if is_spotify_playing; then
        # Get current track
        CURRENT_TRACK=$(get_current_track)
        
        # If track changed, update wallpaper
        if [[ "$CURRENT_TRACK" != "$LAST_TRACK" ]]; then
            echo "Track changed: $CURRENT_TRACK"
            apply_spotify_wallpaper
            LAST_TRACK="$CURRENT_TRACK"
        fi
    else
        # If not playing and we were using Spotify wallpaper before, switch to random
        if $USING_SPOTIFY; then
            echo "Spotify stopped playing"
            apply_random_wallpaper "force"
            LAST_TRACK=""
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done