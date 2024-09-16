#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to display menu and get selections
display_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=()
    
    while true; do
        echo "$title" >&2
        echo "------------------------" >&2
        for i in "${!options[@]}"; do
            if [[ " ${selected[*]} " =~ " $i " ]]; then
                echo "[X] $((i+1)). ${options[$i]}" >&2
            else
                echo "[ ] $((i+1)). ${options[$i]}" >&2
            fi
        done
        echo "------------------------" >&2
        echo "Enter a number to select/deselect, 'done' to finish, or 'quit' to exit:" >&2
        read -r choice
        
        if [ "$choice" = "done" ]; then
            break
        elif [ "$choice" = "quit" ]; then
            exit 0
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            index=$((choice-1))
            if [[ " ${selected[*]} " =~ " $index " ]]; then
                selected=(${selected[@]/$index})
                echo "Deselected ${options[$index]}" >&2
            else
                selected+=("$index")
                echo "Selected ${options[$index]}" >&2
            fi
        else
            echo "Invalid option. Please try again." >&2
        fi
    done
    
    # Return selected options
    for index in "${selected[@]}"; do
        echo "${options[$index]}"
    done
}

# Get shared media directory
read -p "Enter the path for the shared media directory: " shared_media_dir
echo "Debug: Shared media directory: $shared_media_dir"

# Create appdata directory
appdata_dir="$HOME/appdata"
echo "Debug: Appdata directory: $appdata_dir"

# Select media applications
echo "Selecting media applications..."
media_names=("plex" "emby" "jellyfin" "kodi" "airsonic")
selected_media=$(display_menu "Select Media Applications" "${media_names[@]}")

echo "Debug: Selected media applications:"
echo "$selected_media"

# Select torrent downloaders
echo "Selecting torrent downloaders..."
downloader_names=("transmission" "deluge" "qbittorrent")
selected_downloaders=$(display_menu "Select Torrent Downloaders" "${downloader_names[@]}")

echo "Debug: Selected torrent downloaders:"
echo "$selected_downloaders"

echo "Debug: Script ended"