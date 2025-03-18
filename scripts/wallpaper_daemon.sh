#!/bin/bash
# wallpaper_menu.sh - Wofi menu for controlling the wallpaper daemon

# Paths to scripts
DAEMON_SCRIPT="$HOME/.config/hypr/scripts/wallpaper_daemon.sh"

# Check if required commands exist
if ! command -v wofi &>/dev/null; then
	notify-send "Wallpaper Menu" "wofi is not installed"
	exit 1
fi

# Check if notification command exists
NOTIFY_CMD="notify-send"
if ! command -v $NOTIFY_CMD &>/dev/null; then
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

# Function to check if daemon is running
is_daemon_running() {
	if [ -f "$HOME/.config/wallpaper-daemon/daemon.pid" ]; then
		if ps -p "$(cat "$HOME/.config/wallpaper-daemon/daemon.pid")" &>/dev/null; then
			return 0 # True
		fi
	fi
	return 1 # False
}

# Function to get current mode
get_current_mode() {
	if [ -f "$HOME/.config/wallpaper-daemon/mode" ]; then
		cat "$HOME/.config/wallpaper-daemon/mode"
	else
		echo "unknown"
	fi
}

# Function to get current status text for menu
get_status_text() {
	if is_daemon_enabled && is_daemon_running; then
		echo "● Disable Auto-Switching"
	else
		echo "○ Enable Auto-Switching"
	fi
}

# Menu options
gen_menu() {
	local current_mode=$(get_current_mode)

	if [ "$current_mode" = "spotify" ]; then
		echo "🎵 Switch to Spotify Mode ✓"
	else
		echo "🎵 Switch to Spotify Mode"
	fi

	if [ "$current_mode" = "random" ]; then
		echo "🖼️ Switch to Random Mode ✓"
	else
		echo "🖼️ Switch to Random Mode"
	fi

	echo "🔄 Refresh Current Wallpaper"
	echo "$(get_status_text)"
	echo "📋 Show Status"
	echo "🔍 List Running Instances"
	echo "🔄 Restart Daemon"
}

# Handle menu selection
handle_selection() {
	case "$1" in
	*"Switch to Spotify Mode"*)
		"$DAEMON_SCRIPT" spotify
		notify "Switched to Spotify album art mode"
		;;
	*"Switch to Random Mode"*)
		"$DAEMON_SCRIPT" random
		notify "Switched to random wallpaper mode"
		;;
	"🔄 Refresh Current Wallpaper")
		local current_mode=$(get_current_mode)
		if [ "$current_mode" = "spotify" ] && playerctl --player=spotify status 2>/dev/null | grep -q "Playing"; then
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
	"🔍 List Running Instances")
		instances=$("$DAEMON_SCRIPT" list)
		notify "$instances"
		;;
	"🔄 Restart Daemon")
		"$DAEMON_SCRIPT" restart
		notify "Daemon restarted"
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
		--width 500 \
		--lines 8)

	if [ -n "$selection" ]; then
		handle_selection "$selection"
	fi
}

main "$@"
