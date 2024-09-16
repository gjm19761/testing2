#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to display menu and get selections
display_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo "Debug: Entering display_menu function" >&2
    echo "Debug: Title: $title" >&2
    echo "Debug: Number of options: ${#options[@]}" >&2
    echo "Debug: Options: ${options[*]}" >&2
    
    echo "$title" >&2
    echo "------------------------" >&2
    for i in "${!options[@]}"; do
        echo "$((i+1)). ${options[$i]}" >&2
    done
    echo "------------------------" >&2
    echo "Enter the numbers of your choices separated by spaces, then press Enter:" >&2
    read -r choices
    
    echo "Debug: User input: $choices" >&2
    
    local selected=()
    for choice in $choices; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            selected+=("${options[$((choice-1))]}")
        fi
    done
    
    echo "Debug: Selected options: ${selected[*]}" >&2
    printf '%s\n' "${selected[@]}"
}

# ... (rest of the functions remain the same)

# Main script starts here
echo "Debug: Script started"

# Get shared media directory
read -p "Enter the path for the shared media directory: " shared_media_dir
echo "Debug: Shared media directory: $shared_media_dir"

# Create appdata directory
appdata_dir="$HOME/appdata"
echo "Debug: Appdata directory: $appdata_dir"

# Select media applications
echo "Selecting media applications..."
media_names=(plex emby jellyfin sonarr radarr lidarr jackett ombi overseerr)
echo "Debug: Media names: ${media_names[*]}"
mapfile -t selected_media < <(display_menu "Select Media Applications" "${media_names[@]}")

echo "Debug: Selected media applications:"
printf '%s\n' "${selected_media[@]}"

# Select torrent downloaders
echo "Selecting torrent downloaders..."
downloader_names=(transmission deluge qbittorrent rtorrent-rutorrent)
echo "Debug: Downloader names: ${downloader_names[*]}"
mapfile -t selected_downloaders < <(display_menu "Select Torrent Downloaders" "${downloader_names[@]}")

echo "Debug: Selected torrent downloaders:"
printf '%s\n' "${selected_downloaders[@]}"

# Create Docker network
create_docker_network

# Create Docker Compose files and start containers
echo "Creating Docker Compose files and starting containers..."
for app in "${selected_media[@]}" "${selected_downloaders[@]}"; do
    case $app in
        plex) port=32400 ;;
        emby|jellyfin) port=8096 ;;
        sonarr) port=8989 ;;
        radarr) port=7878 ;;
        lidarr) port=8686 ;;
        jackett) port=9117 ;;
        ombi) port=3579 ;;
        overseerr) port=5055 ;;
        transmission) port=9091 ;;
        deluge) port=8112 ;;
        qbittorrent) port=8080 ;;
        rtorrent-rutorrent) port=80 ;;
        *) echo "Unknown application: $app"; continue ;;
    esac
    
    create_docker_compose "$app" "$port"
    (cd "$appdata_dir/$app" && docker-compose up -d)
done

echo "All selected containers have been configured and started."
echo "Please check individual container logs for any issues."
echo "Debug: Script ended"