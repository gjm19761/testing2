
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

echo "Debug: Script started"

display_menu() {
    echo "Debug: Entered display_menu function"
    echo "Debug: Number of arguments: $#"
    echo "Debug: Title: $1"
    shift
    echo "Debug: Number of options: $#"
    echo "Debug: First few options:"
    printf '  %s\n' "${@:1:5}"
    
    # For testing, just return the first option
    echo "$1"
}

echo "Debug: Before media_names array"

media_names=(
    "plex" "emby" "jellyfin" "kodi" "airsonic"
    "beets" "calibre-web" "deemix" "dizquetv" "filebrowser"
)

echo "Debug: After media_names array"
echo "Debug: Number of media_names: ${#media_names[@]}"

echo "Debug: About to call display_menu function"
echo "Debug: Title argument: Select Media Applications"
echo "Debug: Number of options: ${#media_names[@]}"
echo "Debug: First few options:"
printf '  %s\n' "${media_names[@]:0:5}"

selected_media=$(display_menu "Select Media Applications" "${media_names[@]}")

echo "Debug: After display_menu call"
echo "Debug: Selected media: $selected_media"

echo "Debug: Script ended"