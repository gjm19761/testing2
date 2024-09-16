#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to display menu and get selections
display_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=()
    
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
        echo "Enter a number to select/deselect, 'done' to finish, or 'quit' to exit:"
        read -r choice
        
        if [ "$choice" = "done" ]; then
            break
        elif [ "$choice" = "quit" ]; then
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
    
    # Return selected options
    for index in "${selected[@]}"; do
        echo "${options[$index]}"
    done
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
      - 8920:8920 #optional
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
      - 8920:8920 #optional
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
        transmission)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/transmission
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - TRANSMISSION_WEB_HOME=/combustion-release/ #optional
    volumes:
      - $config_dir:/config
      - $shared_media_dir/downloads:/downloads
      - $shared_media_dir/watch:/watch
    ports:
      - $port:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        deluge)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/deluge
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - DELUGE_LOGLEVEL=error #optional
    volumes:
      - $config_dir:/config
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:8112
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        qbittorrent)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/qbittorrent
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - WEBUI_PORT=$port
    volumes:
      - $config_dir:/config
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:$port
      - 6881:6881
      - 6881:6881/udp
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
      - AUTO_UPDATE=true #optional
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
        ombi)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/ombi
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - BASE_URL=/ombi #optional
    volumes:
      - $config_dir:/config
    ports:
      - $port:3579
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        overseerr)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/overseerr
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
    ports:
      - $port:5055
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
media_names=("plex" "emby" "jellyfin" "airsonic" "sonarr" "radarr" "lidarr" "jackett" "ombi" "overseerr")
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
        rtorrent-rutorrent) port=80 ;;
        ombi) port=3579 ;;
        overseerr) port=5055 ;;
        *) echo "Unknown application: $app"; continue ;;
    esac
    
    create_docker_compose "$app" "$port"
    (cd "$appdata_dir/$app" && docker-compose up -d)
done

echo "All selected containers have been configured and started."
echo "Please check individual container logs for any issues."