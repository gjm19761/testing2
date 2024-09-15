#!/bin/bash

set -x  # Enable debug mode

# Function to create directory if it doesn't exist
create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Created directory: $1"
    fi
}

# Ask user about shared directory
read -p "Do you want to use a shared directory for media? (y/n): " use_shared_dir
if [[ $use_shared_dir =~ ^[Yy]$ ]]; then
    read -p "Enter the path for the shared media directory: " shared_media_dir
    create_directory "$shared_media_dir"
    shared_volume_arg="-v $shared_media_dir:/media"
else
    shared_volume_arg=""
fi

echo "Debug: Shared volume arg is $shared_volume_arg"

# Create appdata directory in user's home
appdata_dir="$HOME/appdata"
create_directory "$appdata_dir"

echo "Debug: Appdata directory is $appdata_dir"

# Simplified media containers and torrent downloaders arrays
media_containers=(
    "plex:32400:plexinc/pms-docker"
    "emby:8096:emby/embyserver"
    "jellyfin:8920:jellyfin/jellyfin"
)

torrent_downloaders=(
    "rtorrent-rutorrent:8080:diameter/rtorrent-rutorrent:latest"
    "deluge:8112:linuxserver/deluge"
)

echo "Debug: Arrays defined"

# Simplified selection function
select_items() {
    local title="$1"
    shift
    local array=("$@")
    
    echo "$title"
    for i in "${!array[@]}"; do
        echo "$((i+1)). ${array[$i]%%:*}"
    done
    
    read -p "Enter your choice (1-${#array[@]}, or 0 for none): " choice
    
    if [[ $choice -eq 0 ]]; then
        echo ""
    elif [[ $choice -ge 1 && $choice -le ${#array[@]} ]]; then
        echo "${array[$((choice-1))]}"
    else
        echo "Invalid choice. No selection made."
    fi
}

echo "Debug: Before media selection"

# Select media application
selected_media=$(select_items "Select a media application:" "${media_containers[@]}")

echo "Debug: Media selection done. Selected: $selected_media"

# Select torrent downloader
selected_torrent=$(select_items "Select a torrent downloader:" "${torrent_downloaders[@]}")

echo "Debug: Torrent selection done. Selected: $selected_torrent"

echo "Debug: Script completed"