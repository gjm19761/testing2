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

# Function to select items from an array
select_items() {
    local title="$1"
    shift
    local array=("$@")
    local selected=()
    local choice

    echo "$title"
    echo "Enter the numbers of your choices (space-separated), 0 for none, or q to quit:"
    echo "Available options:"
    for i in "${!array[@]}"; do
        echo "$((i+1)). ${array[$i]%%:*}"
    done

    while true; do
        read -r choice
        if [[ "$choice" == "q" ]]; then
            echo "Exiting script."
            exit 0
        elif [[ "$choice" == "0" ]]; then
            break
        elif [[ "$choice" =~ ^[0-9]+( [0-9]+)*$ ]]; then
            for num in $choice; do
                if (( num > 0 && num <= ${#array[@]} )); then
                    selected+=("${array[$((num-1))]}")
                fi
            done
            break
        else
            echo "Invalid input. Please try again."
        fi
    done

    echo "${selected[@]}"
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

# Create appdata directory in user's home
appdata_dir="$HOME/appdata"
create_directory "$appdata_dir"

# Arrays of media containers and torrent downloaders with their correct repositories
media_containers=(
    "plex:32400:plexinc/pms-docker"
    "emby:8096:emby/embyserver"
    "jellyfin:8920:jellyfin/jellyfin"
    "airsonic:4040:airsonic/airsonic"
    "beets:8337:linuxserver/beets"
    "calibre-web:8083:linuxserver/calibre-web"
    "deemix:6595:registry.gitlab.com/bockiii/deemix-docker"
    "dizquetv:8000:vexorian/dizquetv"
    "filebrowser:8090:filebrowser/filebrowser"
    "freshrss:8081:linuxserver/freshrss"
    "grocy:8082:linuxserver/grocy"
    "headphones:8181:linuxserver/headphones"
    "heimdall:8085:linuxserver/heimdall"
    "jackett:9117:linuxserver/jackett"
    "jellyseerr:5055:fallenbagel/jellyseerr"
    "kavita:5000:kizaing/kavita"
    "komga:8086:gotson/komga"
    "lazylibrarian:5299:linuxserver/lazylibrarian"
    "lidarr:8686:linuxserver/lidarr"
    "lychee:8087:linuxserver/lychee"
    "mediaelch:8088:koenkk/mediaelch"
    "medusa:8081:linuxserver/medusa"
    "mstream:3000:linuxserver/mstream"
    "mylar3:8090:linuxserver/mylar3"
    "navidrome:4533:deluan/navidrome"
    "nzbget:6789:linuxserver/nzbget"
    "nzbhydra2:5076:linuxserver/nzbhydra2"
    "ombi:3579:linuxserver/ombi"
    "organizr:8089:organizr/organizr"
    "photoprism:2342:photoprism/photoprism"
    "photoview:8091:viktorstrate/photoview"
    "piwigo:8092:linuxserver/piwigo"
    "prowlarr:9696:linuxserver/prowlarr"
    "radarr:7878:linuxserver/radarr"
    "readarr:8787:linuxserver/readarr"
    "requestrr:4545:darkalfx/requestrr"
    "sickchill:8081:linuxserver/sickchill"
    "sonarr:8989:linuxserver/sonarr"
    "stash:9999:stashapp/stash"
    "tautulli:8181:tautulli/tautulli"
    "ubooquity:2202:linuxserver/ubooquity"
    "unmanic:8888:josh5/unmanic"
    "watchtower:8093:containrrr/watchtower"
    "yacht:8094:selfhostedpro/yacht"
    "yourls:8095:yourls/yourls"
    "znc:6697:linuxserver/znc"
    "airsonic-advanced:4040:airsonic/airsonic-advanced"
    "bazarr:6767:linuxserver/bazarr"
)

torrent_downloaders=(
    "rtorrent-rutorrent:8080:diameter/rtorrent-rutorrent:latest"
    "deluge:8112:linuxserver/deluge"
    "qbittorrent:8080:linuxserver/qbittorrent"
    "aria2:6800:p3terx/aria2-pro"
)

# Function to create configuration and start container
create_config_and_start() {
    local name=$1
    local port=$2
    local image=$3
    local config_dir="$appdata_dir/$name"
    create_directory "$config_dir"
    
    echo "Starting $name container..."
    case $name in
        plex)
            read -p "Enter your Plex claim code (get it from https://www.plex.tv/claim): " plex_claim
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:32400 \
                -e TZ="Europe/London" \
                -e PLEX_CLAIM="$plex_claim" \
                -v $config_dir:/config \
                $shared_volume_arg \
                $image
            ;;
        rtorrent-rutorrent)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:80 \
                -p 49160:49160/udp \
                -p 49161:49161 \
                -e TZ="Europe/London" \
                -e USR_ID=1000 \
                -e GRP_ID=1000 \
                -v $config_dir:/downloads \
                $shared_volume_arg \
                $image
            ;;
        *)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:$port \
                -e TZ="Europe/London" \
                -e PUID=1000 \
                -e PGID=1000 \
                -v $config_dir:/config \
                $shared_volume_arg \
                $image
            ;;
    esac
    
    echo "$name container started."
}

# Select media applications
selected_media=($(select_items "Select media applications:" "${media_containers[@]}"))

# Select torrent downloaders
selected_torrent=($(select_items "Select torrent downloaders:" "${torrent_downloaders[@]}"))

# Create configurations and start containers for selected media applications
for container in "${selected_media[@]}"; do
    IFS=':' read -r name port image <<< "$container"
    create_config_and_start "$name" "$port" "$image"
done

# Create configurations and start containers for selected torrent downloaders
for downloader in "${selected_torrent[@]}"; do
    IFS=':' read -r name port image <<< "$downloader"
    create_config_and_start "$name" "$port" "$image"
done

if [[ ${#selected_media[@]} -eq 0 && ${#selected_torrent[@]} -eq 0 ]]; then
    echo "No applications were selected. Exiting."
else
    echo "All selected containers have been configured and started. Please check individual container logs for any issues."
fi