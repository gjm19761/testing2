#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

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
            echo "Debug: Selection completed. Number of selections: ${#selected[@]}" >&2
            break
        elif [ "$choice" = "quit" ]; then
            echo "Exiting script." >&2
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
    
    echo "Debug: Final selections:" >&2
    if [ ${#selected[@]} -eq 0 ]; then
        echo "No items were selected." >&2
    else
        for index in "${selected[@]}"; do
            echo "${options[$index]}" >&2
            echo "${options[$index]}"
        done
    fi
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
if [ -z "$selected_media" ]; then
    echo "Debug: No media applications were selected."
else
    echo "Debug: Selected media:"
    echo "$selected_media"
fi

echo "Debug: Script ended"
