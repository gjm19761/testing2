#!/bin/bash

set -x  # Enable debug mode to print each command as it's executed
set -e  # Exit immediately if a command exits with a non-zero status.

echo "Debug: Script started"

display_menu() {
    echo "Debug: Entered display_menu function" >&2
    local title="$1"
    shift
    local options=("$@")
    
    echo "Debug: Title: $title" >&2
    echo "Debug: Number of options: ${#options[@]}" >&2
    
    echo "Debug: About to enter while loop" >&2
    while true; do
        echo "Debug: Top of while loop" >&2
        echo "$title"
        echo "------------------------"
        echo "Debug: About to list options" >&2
        for i in "${!options[@]}"; do
            echo "Debug: Processing option $i" >&2
            echo "$((i+1)). ${options[$i]}"
        done
        echo "------------------------"
        echo "Enter 'done' to finish, or 'quit' to exit:"
        echo "Debug: About to read user input" >&2
        choice=""
        read choice
        echo "Debug: User input: $choice" >&2
        
        if [ "$choice" = "done" ]; then
            echo "Debug: Selection completed" >&2
            break
        elif [ "$choice" = "quit" ]; then
            echo "Debug: User chose to quit" >&2
            exit 0
        else
            echo "Invalid option. Please try again."
            sleep 1
        fi
    done
    
    echo "Debug: Exited while loop" >&2
    
    # For testing, just return the first option
    echo "${options[0]}"
}

echo "Debug: Before media_names array"

media_names=(
    "plex" "emby" "jellyfin" "kodi" "airsonic"
)

echo "Debug: After media_names array"
echo "Debug: Number of media_names: ${#media_names[@]}"

echo "Debug: About to call display_menu function"
selected_media=$(display_menu "Select Media Applications" "${media_names[@]}")

echo "Debug: After display_menu call"
echo "Debug: Selected media: $selected_media"

echo "Debug: Script ended"