#!/bin/bash
# wallpaper_daemon.sh - Monitors media players and switches wallpapers accordingly

# Configuration
SCRIPT_DIR="$HOME/.config/hypr/scripts"  # Hard-coded script directory
CONFIG_DIR="$HOME/.config/wallpaper-daemon"
ENABLED_FILE="$CONFIG_DIR/enabled"
MODE_FILE="$CONFIG_DIR/mode"  # New file to store the current mode
LOCK_FILE="$CONFIG_DIR/daemon.lock"  # Lock file to prevent multiple instances
PID_FILE="$CONFIG_DIR/daemon.pid"    # PID file to track running instance
CACHE_DIR="$HOME/.cache/wal"
CHECK_INTERVAL=5  # Check every 5 seconds
LOG_FILE="$CONFIG_DIR/daemon.log"    # Log file for all messages

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

# Initialize mode if it doesn't exist (default to "random")
if [[ ! -f "$MODE_FILE" ]]; then
    echo "random" > "$MODE_FILE"
fi

# Function to check if daemon is already running
is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" &>/dev/null; then
            return 0  # True, process is running
        else
            # Stale PID file
            rm -f "$PID_FILE" "$LOCK_FILE"
            return 1  # False, process is not running
        fi
    else
        return 1  # False, no PID file
    fi
}

# Function to list all running instances
list_instances() {
    echo "Looking for running instances of wallpaper_daemon.sh:" | tee -a "$LOG_FILE"
    ps aux | grep wallpaper_daemon.sh | grep -v grep | tee -a "$LOG_FILE"
    echo "Total count: $(ps aux | grep wallpaper_daemon.sh | grep -v grep | wc -l)" | tee -a "$LOG_FILE"
}

# Function to kill all running instances
kill_instances() {
    echo "Killing all running instances of wallpaper_daemon.sh..." | tee -a "$LOG_FILE"
    pkill -f wallpaper_daemon.sh
    rm -f "$PID_FILE" "$LOCK_FILE"
    echo "Done. Wait a moment to ensure all processes exit cleanly." | tee -a "$LOG_FILE"
    sleep 1
    list_instances
}

# Function to verify all scripts exist
check_scripts() {
    local missing=false
    
    if [[ ! -f "$RANDOM_WALLPAPER_SCRIPT" ]]; then
        echo "Error: Random wallpaper script not found at $RANDOM_WALLPAPER_SCRIPT" >> "$LOG_FILE"
        missing=true
    fi
    
    if [[ ! -f "$SPOTIFY_WALLPAPER_SCRIPT" ]]; then
        echo "Error: Spotify wallpaper script not found at $SPOTIFY_WALLPAPER_SCRIPT" >> "$LOG_FILE"
        missing=true
    fi
    
    if [[ ! -f "$APPLY_WALLPAPER_SCRIPT" ]]; then
        echo "Error: Apply wallpaper script not found at $APPLY_WALLPAPER_SCRIPT" >> "$LOG_FILE"
        missing=true
    fi
    
    if $missing; then
        echo "Please ensure all required scripts are installed in $SCRIPT_DIR" >> "$LOG_FILE"
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

# Function to get current mode
get_mode() {
    cat "$MODE_FILE"
}

# Function to toggle daemon enabled/disabled
toggle_daemon() {
    if is_enabled; then
        echo "false" > "$ENABLED_FILE"
        echo "Wallpaper daemon disabled" | tee -a "$LOG_FILE"
    else
        echo "true" > "$ENABLED_FILE"
        echo "Wallpaper daemon enabled" | tee -a "$LOG_FILE"
    fi
}

# Function to set daemon mode
set_mode() {
    if [[ "$1" == "random" || "$1" == "spotify" ]]; then
        echo "$1" > "$MODE_FILE"
        echo "Wallpaper daemon mode set to $1" | tee -a "$LOG_FILE"
        return 0
    else
        echo "Invalid mode: $1. Valid modes are 'random' or 'spotify'" >> "$LOG_FILE"
        return 1
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

# Function to get current track ID
get_current_track_id() {
    playerctl --player=spotify metadata mpris:trackid 2>/dev/null || echo ""
}

# Function to apply random wallpaper
apply_random_wallpaper() {
    local current_mode=$(get_mode)
    if [ "$current_mode" == "random" ] || [ "$1" == "force" ]; then
        echo "Applying random wallpaper" >> "$LOG_FILE"
        # Fallback to a direct wallpaper path if the script fails
        if ! "$RANDOM_WALLPAPER_SCRIPT" | "$APPLY_WALLPAPER_SCRIPT"; then
            if [ -d "$HOME/Pictures/bg" ]; then
                find "$HOME/Pictures/bg" -type f | grep -E '\.(jpg|png|jpeg)$' | shuf -n 1 | "$APPLY_WALLPAPER_SCRIPT"
            else
                echo "Failed to apply random wallpaper and no fallback directory found" >> "$LOG_FILE"
            fi
        fi
    fi
}

# Function to apply Spotify wallpaper
apply_spotify_wallpaper() {
    local current_mode=$(get_mode)
    if [ "$current_mode" == "spotify" ] || [ "$1" == "force" ]; then
        echo "Applying Spotify wallpaper" >> "$LOG_FILE"
        
        # First, store the current track ID to ensure we're processing the right track
        CURRENT_TRACK_ID=$(get_current_track_id)
        
        if [[ -z "$CURRENT_TRACK_ID" ]]; then
            echo "No track playing, skipping update" >> "$LOG_FILE"
            return
        fi
        
        sleep 1
        
        # Check if track changed during our delay
        NEW_TRACK_ID=$(get_current_track_id)
        if [[ "$CURRENT_TRACK_ID" != "$NEW_TRACK_ID" ]]; then
            echo "Track changed during delay, skipping this update" >> "$LOG_FILE"
            return
        fi
        
        if ! "$SPOTIFY_WALLPAPER_SCRIPT" | "$APPLY_WALLPAPER_SCRIPT"; then
            echo "Failed to apply Spotify wallpaper, falling back to random" >> "$LOG_FILE"
            # Even in Spotify mode, we fall back to random if the Spotify script fails
            "$RANDOM_WALLPAPER_SCRIPT" | "$APPLY_WALLPAPER_SCRIPT"
            return
        fi
    fi
}

# Current state tracking
LAST_TRACK_ID=""

# Initialize log file with timestamp header for this run
log_header() {
    echo "=== Wallpaper Daemon Log ($(date '+%F_%H:%M:%S')) ===" > "$LOG_FILE"
    echo "Command: $0 $*" >> "$LOG_FILE"
}

# Parse command line arguments
log_header "$@"

case "$1" in
    toggle)
        toggle_daemon
        exit 0
        ;;
    status)
        if is_enabled; then
            echo "Wallpaper daemon is enabled" | tee -a "$LOG_FILE"
            echo "Current mode: $(get_mode)" | tee -a "$LOG_FILE"
            if is_running; then
                echo "Daemon is running with PID $(cat "$PID_FILE")" | tee -a "$LOG_FILE"
            else
                echo "Daemon is not running" | tee -a "$LOG_FILE"
            fi
            echo "Using scripts:" | tee -a "$LOG_FILE"
            echo "  Random: $RANDOM_WALLPAPER_SCRIPT" | tee -a "$LOG_FILE"
            echo "  Spotify: $SPOTIFY_WALLPAPER_SCRIPT" | tee -a "$LOG_FILE"
            echo "  Apply: $APPLY_WALLPAPER_SCRIPT" | tee -a "$LOG_FILE"
        else
            echo "Wallpaper daemon is disabled" | tee -a "$LOG_FILE"
            if is_running; then
                echo "Daemon is running with PID $(cat "$PID_FILE") (will exit on next check)" | tee -a "$LOG_FILE"
            else
                echo "Daemon is not running" | tee -a "$LOG_FILE"
            fi
        fi
        exit 0
        ;;
    start)
        echo "true" > "$ENABLED_FILE"
        echo "Wallpaper daemon enabled" | tee -a "$LOG_FILE"
        
        if is_running; then
            echo "Daemon is already running with PID $(cat "$PID_FILE")" | tee -a "$LOG_FILE"
            exit 0
        fi
        
        # Start the daemon by running the script in the background
        nohup "$0" &>/dev/null &
        echo "Daemon started with PID $!" | tee -a "$LOG_FILE"
        exit 0
        ;;
    stop)
        echo "false" > "$ENABLED_FILE"
        echo "Wallpaper daemon disabled" | tee -a "$LOG_FILE"
        
        if is_running; then
            echo "Sending termination signal to daemon (PID $(cat "$PID_FILE"))" | tee -a "$LOG_FILE"
            kill "$(cat "$PID_FILE")"
            rm -f "$PID_FILE" "$LOCK_FILE"
        else
            echo "Daemon is not running" | tee -a "$LOG_FILE"
        fi
        exit 0
        ;;
    ps|list)
        list_instances
        exit 0
        ;;
    killall)
        kill_instances
        exit 0
        ;;
    restart)
        kill_instances
        sleep 1
        nohup "$0" &>/dev/null &
        echo "Daemon restarted with PID $!" | tee -a "$LOG_FILE"
        exit 0
        ;;
    spotify)
        # Switch to Spotify mode and force apply a Spotify wallpaper
        check_scripts
        set_mode "spotify"
        # Apply if Spotify is playing
        if is_spotify_playing; then
            apply_spotify_wallpaper "force"
        else
            echo "Spotify is not playing. Mode set to spotify but using random wallpaper until music starts." | tee -a "$LOG_FILE"
            apply_random_wallpaper "force"
        fi
        exit 0
        ;;
    random)
        # Switch to random mode and force apply a random wallpaper
        check_scripts
        set_mode "random"
        apply_random_wallpaper "force"
        exit 0
        ;;
    mode)
        # Show or set the current mode
        if [[ -z "$2" ]]; then
            echo "Current mode: $(get_mode)" | tee -a "$LOG_FILE"
        else
            set_mode "$2"
            
            # Apply wallpaper based on new mode
            if [[ "$2" == "random" ]]; then
                apply_random_wallpaper "force"
            elif [[ "$2" == "spotify" ]]; then
                if is_spotify_playing; then
                    apply_spotify_wallpaper "force"
                else
                    apply_random_wallpaper "force"
                fi
            fi
        fi
        exit 0
        ;;
    setup)
        echo "Setting up wallpaper daemon scripts..." | tee -a "$LOG_FILE"
        # Make all scripts executable
        chmod +x "$RANDOM_WALLPAPER_SCRIPT" "$SPOTIFY_WALLPAPER_SCRIPT" "$APPLY_WALLPAPER_SCRIPT" "$SCRIPT_DIR/wallpaper_daemon.sh"
        echo "Scripts are ready to use in $SCRIPT_DIR" | tee -a "$LOG_FILE"
        exit 0
        ;;
    *)
        # Continue to main loop for daemon mode
        ;;
esac

# Check if we're running in daemon mode
if [[ "$1" == "" ]]; then
    # Check if daemon is already running
    if is_running; then
        echo "Daemon is already running with PID $(cat "$PID_FILE")" >> "$LOG_FILE"
        echo "Only one instance of the daemon should run at a time." >> "$LOG_FILE"
        echo "Use 'killall' to kill all instances or 'restart' to restart." >> "$LOG_FILE"
        exit 1
    fi
    
    # Verify scripts exist before starting daemon
    if ! check_scripts; then
        exit 1
    fi
    
    # Create lock file and save PID
    echo $$ > "$PID_FILE"
    
    # Main loop
    echo "Starting wallpaper daemon with PID $$..." >> "$LOG_FILE"
    
    # Apply initial wallpaper based on mode
    current_mode=$(get_mode)
    echo "Initial mode: $current_mode" >> "$LOG_FILE"
    
    if [ "$current_mode" == "spotify" ] && is_spotify_playing; then
        apply_spotify_wallpaper "force"
    else
        apply_random_wallpaper "force"
    fi
    
    while true; do
        # Check if daemon is enabled
        if ! is_enabled; then
            echo "Daemon is disabled, exiting..." >> "$LOG_FILE"
            rm -f "$PID_FILE" "$LOCK_FILE"
            exit 0
        fi
        
        # Get current mode - read fresh each time
        current_mode=$(get_mode)
        
        # Handle based on mode
        if [ "$current_mode" == "spotify" ]; then
            # We're in Spotify mode
            if is_spotify_playing; then
                # Get current track ID
                CURRENT_TRACK_ID=$(get_current_track_id)
                
                # If track changed, update wallpaper
                if [[ -n "$CURRENT_TRACK_ID" && "$CURRENT_TRACK_ID" != "$LAST_TRACK_ID" ]]; then
                    CURRENT_TRACK=$(get_current_track)
                    echo "$(date '+%H:%M:%S') - Track changed to '$CURRENT_TRACK'" >> "$LOG_FILE"
                    apply_spotify_wallpaper
                    LAST_TRACK_ID="$CURRENT_TRACK_ID"
                fi
            fi
        elif [ "$current_mode" == "random" ]; then
            # We're in Random mode - do nothing as wallpaper is set elsewhere
            :
        fi
        
        sleep "$CHECK_INTERVAL"
    done
fi