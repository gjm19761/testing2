#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to display menu and get selections
display_menu() {
    # ... (keep the existing display_menu function)
}

# Function to create Docker network
create_docker_network() {
    # ... (keep the existing create_docker_network function)
}

# Function to create Docker Compose file
create_docker_compose() {
    local name=$1
    local port=$2
    local config_dir="$appdata_dir/$name"
    mkdir -p "$config_dir"
    
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
        emby)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: emby/embyserver
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
EOL
            ;;
        jellyfin)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: jellyfin/jellyfin
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
EOL
            ;;
        airsonic)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: airsonic/airsonic
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - JAVA_OPTS=-Dserver.use-forward-headers=true
    volumes:
      - $config_dir:/airsonic/data
      - $shared_media_dir:/airsonic/music
    ports:
      - $port:4040
    restart: unless-stopped
    networks:
      - media_network
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
EOL
            ;;
        sonarr|radarr|lidarr)
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
EOL
            ;;
        jackett)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/jackett
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - AUTO_UPDATE=true
    volumes:
      - $config_dir:/config
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:9117
    restart: unless-stopped
    networks:
      - media_network
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
      - 49160:49160/udp
      - 49161:49161
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        *)
            echo "Unknown application: $name"
            return 1
            ;;
    esac

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
media_names=("plex" "emby" "jellyfin" "airsonic" "sonarr" "radarr" "lidarr" "jackett")
selected_media=$(display_menu "Select Media Applications" "${media_names[@]}")

echo "Selected media applications:"
echo "$selected_media"

# Select torrent downloaders
echo "Selecting torrent downloaders..."
downloader_names=("transmission" "deluge" "qbittorrent" "rtorrent-rutorrent")
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
        emby|jellyfin) port=8096 ;;
        airsonic) port=4040 ;;
        transmission) port=9091 ;;
        deluge) port=8112 ;;
        qbittorrent) port=8080 ;;
        sonarr) port=8989 ;;
        radarr) port=7878 ;;
        lidarr) port=8686 ;;
        jackett) port=9117 ;;
        rtorrent-rutorrent) port=8080 ;;
        *) echo "Unknown application: $app"; continue ;;
    esac
    
    create_docker_compose "$app" "$port"
    (cd "$appdata_dir/$app" && docker-compose up -d)
done

echo "All selected containers have been configured and started."
echo "Please check individual container logs for any issues."