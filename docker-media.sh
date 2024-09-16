#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

echo "Debug: Script started"

display_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=()
    
    echo "Debug: Entered display_menu function" >&2
    echo "Debug: Title: $title" >&2
    echo "Debug: Number of options: ${#options[@]}" >&2
    
    while true; do
        echo "$title"
        echo "------------------------"
        for i in "${!options[@]}"; do
            if [[ " ${selected[*]} " =~ " $i " ]]; then
                echo "[X] $((i+1)). ${options[$i]}"
            else
                echo "[ ] $((i+1)). ${options[$i]}"
            fi
        done
        echo "------------------------"
        echo "Enter the number to select/deselect an option, 'done' to finish, or 'quit' to exit:"
        read -r choice
        echo "Debug: User input: $choice" >&2
        
        if [[ "$choice" == "done" ]]; then
            echo "Debug: Selection completed" >&2
            break
        elif [[ "$choice" == "quit" ]]; then
            echo "Debug: User chose to quit" >&2
            exit 0
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            index=$((choice-1))
            if [[ " ${selected[*]} " =~ " $index " ]]; then
                selected=(${selected[@]/$index})
                echo "Debug: Deselected option $choice" >&2
            else
                selected+=("$index")
                echo "Debug: Selected option $choice" >&2
            fi
        else
            echo "Invalid option. Please try again."
            sleep 1
        fi
    done
    
    # Return selected options
    for index in "${selected[@]}"; do
        echo "${options[$index]}"
    done
}

echo "Debug: Before media_names array"

media_names=(
    "plex" "emby" "jellyfin" "kodi" "airsonic"
    "beets" "calibre-web" "deemix" "dizquetv" "filebrowser"
)

echo "Debug: After media_names array"
echo "Debug: Number of media_names: ${#media_names[@]}"

echo "Debug: About to call display_menu function"
selected_media=$(display_menu "Select Media Applications" "${media_names[@]}")

echo "Debug: After display_menu call"
echo "Debug: Selected media: $selected_media"

echo "Debug: Script ended"