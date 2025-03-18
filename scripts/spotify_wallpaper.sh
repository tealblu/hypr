#!/bin/bash
# spotify_wallpaper.sh - Creates a wallpaper from Spotify album art

# Configuration
XRES=1920
YRES=1080
CACHE_DIR="$HOME/.cache/wal"
SPOTIFY_DIR="$CACHE_DIR/spotify"
OUTPUT_PATH="$CACHE_DIR/selected_wallpaper.txt"

# Create directories if they don't exist
mkdir -p "$SPOTIFY_DIR"
CURRENT_ALBUM="$SPOTIFY_DIR/current.txt"
LAST_ALBUM="$SPOTIFY_DIR/last.txt"
if [[ ! -f $LAST_ALBUM ]]; then
	touch "$LAST_ALBUM"
fi

# Check if Spotify is running
if ! playerctl --player=spotify status &>/dev/null; then
	echo "Spotify is not running" >&2
	exit 1
fi

# Get current album info
playerctl metadata --player=spotify \
	-f "{{xesam:album}} - {{xesam:albumArtist}}" >"$CURRENT_ALBUM"

# Get album art URL and download it
artUrl=$(playerctl metadata mpris:artUrl --player spotify)
echo "Album art URL: $artUrl" >&2

# Verify we have a valid URL before proceeding
if [[ -z $artUrl || $artUrl == "null" ]]; then
	echo "No valid album art URL found. Waiting and retrying..." >&2
	sleep 3
	artUrl=$(playerctl metadata mpris:artUrl --player spotify)
	echo "Retried album art URL: $artUrl" >&2
	if [[ -z $artUrl || $artUrl == "null" ]]; then
		echo "Still no valid album art URL. Exiting." >&2
		exit 1
	fi
fi

curl -s "$artUrl" -o "$SPOTIFY_DIR/cover.png"

# Create blurred background
convert "$SPOTIFY_DIR/cover.png" \
	-blur 0x8 \
	-modulate 90,120,100 \
	-resize "${XRES}x${YRES}^" \
	-gravity center \
	-extent "${XRES}x${YRES}" \
	"$SPOTIFY_DIR/cover_blurred.png"

# Composite the album art on top of blurred background
composite -gravity center \
	"$SPOTIFY_DIR/cover.png" \
	"$SPOTIFY_DIR/cover_blurred.png" \
	"$SPOTIFY_DIR/background.png"

# Save the path to the created wallpaper
echo "$SPOTIFY_DIR/background.png" >"$OUTPUT_PATH"
echo "$SPOTIFY_DIR/background.png" # Output for use in pipes or variable capture

# Success message
album_name=$(cat "$CURRENT_ALBUM")
echo "Created wallpaper for: $album_name" >&2
