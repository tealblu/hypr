#!/bin/bash
# wallpaper_menu.sh - Wofi menu for controlling the wallpaper daemon

# Paths to scripts
DAEMON_SCRIPT="$HOME/.config/hypr/scripts/wallpaper_daemon.sh"

# Check if required commands exist
if ! command -v wofi &> /dev/null; then
    notify-send "Wallpaper Menu" "wofi is not installed"
    exit 1
fi

# Check if notification command exists
NOTIFY_CMD="notify-send"
if ! command -v $NOTIFY_CMD &> /dev/null; then
    NOTIFY_CMD="echo"
fi

# Function to send notifications
notify() {
    $NOTIFY_CMD "Wallpaper Menu" "$1"
}

# Function to check daemon status
is_daemon_enabled() {
    if [ -f "$HOME/.config/wallpaper-daemon/enabled" ]; then
        if [ "$(cat "$HOME/.config/wallpaper-daemon/enabled")" = "true" ]; then
            return 0 # True
        fi
    fi
    return 1 # False
}

# Function to get current status text for menu
get_status_text() {
    if is_daemon_enabled; then
        echo "● Disable Auto-Switching"
    else
        echo "○ Enable Auto-Switching"
    fi
}

# Menu options
gen_menu() {
    echo "🎵 Use Spotify Album Art"
    echo "🖼️ Use Random Wallpaper"
    echo "🔄 Refresh Current Wallpaper"
    echo "$(get_status_text)"
    echo "📋 Show Status"
}

# Handle menu selection
handle_selection() {
    case "$1" in
        "🎵 Use Spotify Album Art")
            "$DAEMON_SCRIPT" spotify
            notify "Switched to Spotify album art wallpaper"
            ;;
        "🖼️ Use Random Wallpaper")
            "$DAEMON_SCRIPT" random
            notify "Switched to random wallpaper"
            ;;
        "🔄 Refresh Current Wallpaper")
            if is_daemon_enabled && playerctl --player=spotify status 2>/dev/null | grep -q "Playing"; then
                "$DAEMON_SCRIPT" spotify
                notify "Refreshed Spotify wallpaper"
            else
                "$DAEMON_SCRIPT" random
                notify "Refreshed random wallpaper"
            fi
            ;;
        "● Disable Auto-Switching")
            "$DAEMON_SCRIPT" stop
            notify "Auto-switching disabled"
            ;;
        "○ Enable Auto-Switching")
            "$DAEMON_SCRIPT" start
            notify "Auto-switching enabled"
            ;;
        "📋 Show Status")
            status=$("$DAEMON_SCRIPT" status)
            notify "$status"
            ;;
        *)
            notify "Unknown option: $1"
            ;;
    esac
}

# Main execution
main() {
    pkill -x wofi || selection=$(gen_menu | wofi --show dmenu \
                                                  --no-actions \
                                                  --prompt "Wallpaper Menu" \
                                                  --width 250 \
                                                  --lines 6 \
                                                  --style ~/.config/wofi/style.css)
    if [ -n "$selection" ]; then
        handle_selection "$selection"
    fi
}

main "$@"