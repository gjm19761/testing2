#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to display menu and get selections (keep this function as is)
display_menu() {
    # ... (keep the existing display_menu function)
}

# Function to create Docker network
create_docker_network() {
    local network_name="media_network"
    if ! docker network inspect $network_name >/dev/null 2>&1; then
        echo "Creating Docker network: $network_name"
        docker network create $network_name
    else
        echo "Docker network $network_name already exists"
    fi
}

# Function to create Docker Compose file
create_docker_compose() {
    local name=$1
    local port=$2
    local config_dir="$appdata_dir/$name"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/$name
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/media
    ports:
      - $port:$port
    restart: unless-stopped
    networks:
      - media_network

networks:
  media_network:
    external: true
EOL

    echo "Created Docker Compose file for $name"
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

echo "Selected media applications:"
echo "$selected_media"

# Select torrent downloaders
echo "Selecting torrent downloaders..."
downloader_names=("transmission" "deluge" "qbittorrent")
selected_downloaders=$(display_menu "Select Torrent Downloaders" "${downloader_names[@]}")

echo "Selected torrent downloaders:"
echo "$selected_downloaders"

# Create Docker network
create_docker_network

# Create Docker Compose files and start containers
echo "Creating Docker Compose files and starting containers..."
for app in $selected_media $selected_downloaders; do
    case $app in
        plex) port=32400 ;;
        emby) port=8096 ;;
        jellyfin) port=8096 ;;
        kodi) port=8080 ;;
        airsonic) port=4040 ;;
        transmission) port=9091 ;;
        deluge) port=8112 ;;
        qbittorrent) port=8080 ;;
        *) echo "Unknown application: $app"; continue ;;
    esac
    
    create_docker_compose "$app" "$port"
    (cd "$appdata_dir/$app" && docker-compose up -d)
done

echo "All selected containers have been configured and started."
echo "Please check individual container logs for any issues."
