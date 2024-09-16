#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker installed successfully. Please log out and log back in to use Docker without sudo."
}

# Function to install Docker Compose
install_docker_compose() {
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
}

# Check and install Docker if not present
if ! command_exists docker; then
    install_docker
fi

# Check and install Docker Compose if not present
if ! command_exists docker-compose; then
    install_docker_compose
fi

# Function to create directory if it doesn't exist
create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Created directory: $1"
    fi
}

# Arrays of media containers and torrent downloaders
media_containers=(
    "plex:32400" "emby:8096" "jellyfin:8920" "kodi:8080" "airsonic:4040" "beets:8337" "calibre-web:8083" 
    "deemix:6595" "dizquetv:8000" "filebrowser:8090" "freshrss:8081" "grocy:8082" "headphones:8181" 
    "heimdall:8085" "jackett:9117" "jellyseerr:5055" "kavita:5000" "komga:8086" "lazylibrarian:5299" 
    "lidarr:8686" "lychee:8087" "mediaelch:8088" "medusa:8081" "mstream:3000" "mylar3:8090" 
    "navidrome:4533" "nzbget:6789" "nzbhydra2:5076" "ombi:3579" "organizr:8089" "photoprism:2342" 
    "photoview:8091" "piwigo:8092" "prowlarr:9696" "radarr:7878" "readarr:8787" "requestrr:4545" 
    "sickchill:8081" "sonarr:8989" "stash:9999" "tautulli:8181" "transmission:9091" "ubooquity:2202" 
    "unmanic:8888" "watchtower:8093" "yacht:8094" "yourls:8095" "znc:6697" "airsonic-advanced:4040" "bazarr:6767"
)

torrent_downloaders=(
    "transmission:9091" "deluge:8112" "qbittorrent:8080" "rtorrent:5000" "aria2:6800"
)

# Variable to store Plex claim code
plex_claim=""

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

# Function to create configuration and start container
create_config_and_start() {
    local name=$1
    local port=$2
    local config_dir="$appdata_dir/$name"
    create_directory "$config_dir"
    
    echo "Creating Docker Compose file for $name..."
    case $name in
        plex)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: plexinc/pms-docker
    container_name: $name
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM="$plex_claim"
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/media
    ports:
      - $port:32400
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        emby)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: emby/embyserver
    container_name: $name
    environment:
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/media
    ports:
      - $port:8096
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        jellyfin)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: jellyfin/jellyfin
    container_name: $name
    environment:
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/media
    ports:
      - $port:8096
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        transmission)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: linuxserver/transmission
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/media
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:9091
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        deluge)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: linuxserver/deluge
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/media
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:8112
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        qbittorrent)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
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
      - $shared_media_dir:/media
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:$port
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        rtorrent)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: diameter/rtorrent-rutorrent
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/media
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:80
      - 49160:49160/udp
      - 49161:49161
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        aria2)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: p3terx/aria2-pro
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/media
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:6800
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        filebrowser)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: filebrowser/filebrowser
    container_name: $name
    environment:
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/srv
    ports:
      - $port:80
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        ombi)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: linuxserver/ombi
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
    ports:
      - $port:3579
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        stash)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: stashapp/stash
    container_name: $name
    environment:
      - STASH_STASH=/data/
      - STASH_GENERATED=/generated/
      - STASH_METADATA=/metadata/
      - STASH_CACHE=/cache/
    volumes:
      - $config_dir:/root/.stash
      - $shared_media_dir:/data
      - $config_dir/generated:/generated
      - $config_dir/metadata:/metadata
      - $config_dir/cache:/cache
    ports:
      - $port:9999
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        yourls)
            cat > $config_dir/docker-compose.yml <<EOL
version: "3"
services:
  $name:
    image: yourls
    container_name: $name
    environment:
      - YOURLS_DB_HOST=db
      - YOURLS_DB_USER=yourls
      - YOURLS_DB_PASS=yourlspass
      - YOURLS_DB_NAME=yourls
      - YOURLS_SITE=http://your-domain.com
      - YOURLS_USER=admin
      - YOURLS_PASS=password
    volumes:
      - $config_dir:/var/www/html
    ports:
      - $port:80
    restart: unless-stopped
    networks:
      - media_network
EOL
            ;;
        *)
            echo "Docker Compose configuration for $name is not defined."
            return
            ;;
    esac
    
    echo "Docker Compose file created for $name."
}

# Function to ask yes/no question
ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Ask user about shared directory
if ask_yes_no "Do you want to use a shared directory for media?"; then
    read -p "Enter the path for the shared media directory: " shared_media_dir
    create_directory "$shared_media_dir"
else
    shared_media_dir="/media"
fi

echo "Debug: Shared media directory: $shared_media_dir"

# Create appdata directory in user's home
appdata_dir="$HOME/appdata"
create_directory "$appdata_dir"

echo "Debug: Appdata directory: $appdata_dir"

# Select media applications
selected_media=""
for app in "${media_containers[@]}"; do
    IFS=':' read -r name port <<< "$app"
    if ask_yes_no "Do you want to install $name?"; then
        selected_media="$selected_media $name"
    fi
done

echo "Debug: Selected media: $selected_media"

# If no media applications were selected, inform the user and exit
if [ -z "$selected_media" ]; then
    echo "No media applications were selected. Exiting."
    exit 0
fi

# If Plex is selected, ask for claim code
if echo "$selected_media" | grep -q "plex"; then
    read -p "Enter your Plex claim code: " plex_claim
    echo "Debug: Plex claim code: $plex_claim"
    if [ -z "$plex_claim" ]; then
        echo "Plex claim code not provided. Exiting."
        exit 0
    fi
fi

# Select torrent downloaders
selected_downloaders=""
for app in "${torrent_downloaders[@]}"; do
    IFS=':' read -r name port <<< "$app"
    if ask_yes_no "Do you want to install $name?"; then
        selected_downloaders="$selected_downloaders $name"
    fi
done

echo "Debug: Selected downloaders: $selected_downloaders"

# If no torrent downloaders were selected, inform the user
if [ -z "$selected_downloaders" ]; then
    echo "No torrent downloaders were selected."
fi

# Function to get port for a given container name
get_port() {
    local name=$1
    local port
    for container in "${media_containers[@]}" "${torrent_downloaders[@]}"; do
        IFS=':' read -r cname cport <<< "$container"
        if [[ "$name" == "$cname" ]]; then
            port=$cport
            break
        fi
    done
    echo $port
}

# Create Docker network
create_docker_network

# Create configurations for selected media applications
echo "Creating configurations for selected media applications..."
for name in $selected_media; do
    if [ ! -z "$name" ]; then
        port=$(get_port "$name")
        create_config_and_start "$name" "$port"
    fi
done

# Create configurations for selected torrent downloaders
echo "Creating configurations for selected torrent downloaders..."
for name in $selected_downloaders; do
    if [ ! -z "$name" ]; then
        port=$(get_port "$name")
        create_config_and_start "$name" "$port"
    fi
done

# Start all selected applications
echo "Starting all selected applications..."
for name in $selected_media $selected_downloaders; do
    if [ ! -z "$name" ]; then
        config_dir="$appdata_dir/$name"
        if [ -f "$config_dir/docker-compose.yml" ]; then
            echo "Starting $name..."
            docker-compose -f "$config_dir/docker-compose.yml" up -d
        else
            echo "Docker Compose file for $name not found. Skipping..."
        fi
    fi
done

echo "All selected containers have been configured and started.