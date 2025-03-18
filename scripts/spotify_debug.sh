#!/bin/bash
# spotify_debug.sh - Monitor Spotify metadata updates in real-time

echo "Starting Spotify metadata monitoring..."
echo "Press Ctrl+C to exit."
echo "--------------------------------------"

previous_track=""
previous_album=""
previous_art_url=""

while true; do
	# Get current track info
	current_track=$(playerctl --player=spotify metadata --format "{{artist}} - {{title}}" 2>/dev/null)
	current_album=$(playerctl --player=spotify metadata --format "{{album}}" 2>/dev/null)
	current_art_url=$(playerctl --player=spotify metadata mpris:artUrl --player spotify 2>/dev/null)

	# Check if any metadata changed
	if [[ $current_track != "$previous_track" || $current_album != "$previous_album" || $current_art_url != "$previous_art_url" ]]; then
		timestamp=$(date "+%H:%M:%S.%3N")
		echo "[$timestamp] Changes detected:"

		if [[ $current_track != "$previous_track" ]]; then
			echo "  Track: \"$previous_track\" → \"$current_track\""
		fi

		if [[ $current_album != "$previous_album" ]]; then
			echo "  Album: \"$previous_album\" → \"$current_album\""
		fi

		if [[ $current_art_url != "$previous_art_url" ]]; then
			# Show just the last part of the URL to keep output cleaner
			prev_url_short=$(echo "$previous_art_url" | sed 's/.*\//...\//')
			curr_url_short=$(echo "$current_art_url" | sed 's/.*\//...\//')
			echo "  Art URL: \"$prev_url_short\" → \"$curr_url_short\""
		fi

		echo "--------------------------------------"

		# Update previous values
		previous_track="$current_track"
		previous_album="$current_album"
		previous_art_url="$current_art_url"
	fi

	# Sleep briefly to avoid excessive CPU usage
	sleep 0.1
done
