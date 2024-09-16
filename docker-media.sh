#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to display menu and get selections
display_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo "Debug: Entering display_menu function"
    echo "Debug: Title: $title"
    echo "Debug: Number of options: ${#options[@]}"
    echo "Debug: Options: ${options[*]}"
    
    echo "$title"
    echo "------------------------"
    for i in "${!options[@]}"; do
        echo "$((i+1)). ${options[$i]}"
    done
    echo "------------------------"
    echo "Enter the numbers of your choices separated by spaces, then press Enter:"
    read -r choices
    
    echo "Debug: User input: $choices"
    
    local selected=()
    for choice in $choices; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            selected+=("${options[$((choice-1))]}")
        fi
    done
    
    echo "Debug: Selected options: ${selected[*]}"
    echo "${selected[@]}"
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
    
    echo "Debug: Creating Docker Compose file for $name"
    
    case $name in
        plex)
            read -p "Enter your Plex claim code (https://www.plex.tv/claim): " plex_claim
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: plexinc/pms-docker
    container_name: $name
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
      - PLEX_CLAIM=${plex_claim}
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/data
    restart: unless-stopped
EOL
            ;;
        emby|jellyfin)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: ${name}/${name}
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/data
    ports:
      - $port:8096
    restart: unless-stopped
    networks:
      - media_network

networks:
  media_network:
    external: true
EOL
            ;;
        sonarr|radarr|lidarr|jackett|ombi|overseerr)
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
      - $shared_media_dir:/data
    ports:
      - $port:$port
    restart: unless-stopped
    networks:
      - media_network

networks:
  media_network:
    external: true
EOL
            ;;
        transmission|deluge|qbittorrent)
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
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:$port
    restart: unless-stopped
    networks:
      - media_network

networks:
  media_network:
    external: true
EOL
            ;;
        rtorrent-rutorrent)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: diameter/rtorrent-rutorrent:latest
    container_name: $name
    environment:
      - USR_ID=1000
      - GRP_ID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/downloads
    ports:
      - $port:80
    restart: unless-stopped
    networks:
      - media_network

networks:
  media_network:
    external: true
EOL
            ;;
        *)
            echo "Unknown application: $name"
            return 1
            ;;
    esac

    echo "Created Docker Compose file for $name"
}

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
selected_media=$(display_menu "Select Media Applications" "${media_names[@]}")

echo "Debug: Selected media applications:"
echo "$selected_media"

# Select torrent downloaders
echo "Selecting torrent downloaders..."
downloader_names=(transmission deluge qbittorrent rtorrent-rutorrent)
echo "Debug: Downloader names: ${downloader_names[*]}"
selected_downloaders=$(display_menu "Select Torrent Downloaders" "${downloader_names[@]}")

echo "Debug: Selected torrent downloaders:"
echo "$selected_downloaders"

# Create Docker network
create_docker_network

# Create Docker Compose files and start containers
echo "Creating Docker Compose files and starting containers..."
for app in $selected_media $selected_downloaders; do
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