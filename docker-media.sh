#!/bin/bash

set -x  # Enable debug mode to print each command as it's executed
set -e  # Exit immediately if a command exits with a non-zero status.

echo "Debug: Script started"

display_menu() {
    echo "Debug: Entered display_menu function" >&2
    local title="$1"
    shift
    local options=("$@")
    local selected=()
    
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
            if [[ " ${selected[*]} " =~ " $i " ]]; then
                echo "[X] $((i+1)). ${options[$i]}"
            else
                echo "[ ] $((i+1)). ${options[$i]}"
            fi
        done
        echo "------------------------"
        echo "Enter a number to select/deselect, 'done' to finish, or 'quit' to exit:"
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
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            index=$((choice-1))
            if [[ " ${selected[*]} " =~ " $index " ]]; then
                selected=(${selected[@]/$index})
                echo "Deselected ${options[$index]}"
            else
                selected+=("$index")
                echo "Selected ${options[$index]}"
            fi
        else
            echo "Invalid option. Please try again."
        fi
    done
    
    echo "Debug: Exited while loop" >&2
    
    # Return selected options
    for index in "${selected[@]}"; do
        echo "${options[$index]}"
    done
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