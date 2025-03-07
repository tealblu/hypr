#!/bin/zsh

# Get the current monitor configuration for HDMI-A-1
current_state=$(hyprctl monitors | grep "HDMI-A-1")

# Define the keyword for detecting duplicated state
duplicated_keyword="HDMI-A-1"

# Function to set duplicated state
set_duplicated() {
  hyprctl keyword monitor "HDMI-A-1,preferred,auto-right,auto,mirror,DP-2"
}

# Function to set standard state
set_standard() {
  hyprctl reload
  hyprctl keyword monitor "HDMI-A-1,preferred,auto-right,auto"
  sleep 1
  hyprctl dispatch forcerendererreload
}

# Check if the current state includes the 'mirror' keyword
if echo "$current_state" | grep -q "$duplicated_keyword"; then
  echo "Currently in standard state. Switching to duplicated state..."
  set_duplicated
else
  echo "Currently in duplicated state. Switching to standard state..."
  set_standard
fi


