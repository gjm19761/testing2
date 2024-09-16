#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to display menu and get selections
display_menu() {
    echo "Debug: Entered display_menu function"
    local title="$1"
    shift
    local options=("$@")
    
    echo "Debug: Title: $title"
    echo "Debug: Number of options: ${#options[@]}"
    echo "Debug: Options:"
    for opt in "${options[@]}"; do
        echo "  - $opt"
    done
    
    # For debugging, just return the first option
    echo "${options[0]}"
}

# Get shared media directory
read -p "Enter the path for the shared media directory: " shared_media_dir
echo "Debug: Shared media directory: $shared_media_dir"

# Create appdata directory
appdata_dir="$HOME/appdata"
echo "Debug: Appdata directory: $appdata_dir"

# Select media applications
echo "Selecting media applications..."
echo "Debug: About to create media_names array"
media_names=("plex" "emby" "jellyfin" "kodi" "airsonic")
echo "Debug: media_names array created with ${#media_names[@]} elements"

echo "Debug: About to call display_menu function"
echo "Debug: Command: display_menu \"Select Media Applications\" \"\${media_names[@]}\""
selected_media=$(display_menu "Select Media Applications" "${media_names[@]}")

echo "Debug: After display_menu call"
echo "Debug: Selected media: $selected_media"

echo "Debug: Script ended"