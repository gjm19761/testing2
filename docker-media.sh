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

# Function to create a whiptail checklist from an array
create_checklist() {
    local arr=("$@")
    local options=()
    for i in "${!arr[@]}"; do
        IFS=':' read -r name port <<< "${arr[$i]}"
        options+=("$name" "" OFF)
    done
    echo "${options[@]}"
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
    "transmission:9091" "deluge:8112" "qbittorrent:8080" "rtorrent:5000" "aria2:6800" "vuze:9091" 
    "bittorrent:8080" "utorrent:8080" "tixati:8888" "webtorrent:8000"
)

# Variable to store Plex claim code
plex_claim=""

# Function to create configuration and start container
create_config_and_start() {
    local name=$1
    local port=$2
    local config_dir="$appdata_dir/$name"
    create_directory "$config_dir"
    
    echo "Starting $name container..."
    case $name in
        plex)
            if [ -z "$plex_claim" ]; then
                plex_claim=$(whiptail --inputbox "Enter your Plex claim code:" 8 78 --title "Plex Claim Code" 3>&1 1>&2 2>&3)
            fi
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:32400 \
                -e TZ="Europe/London" \
                -e PLEX_CLAIM="$plex_claim" \
                -v $config_dir:/config \
                $shared_volume_arg \
                plexinc/pms-docker
            ;;
        emby)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:8096 \
                -e TZ="Europe/London" \
                -v $config_dir:/config \
                $shared_volume_arg \
                emby/embyserver
            ;;
        jellyfin)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:8096 \
                -e TZ="Europe/London" \
                -v $config_dir:/config \
                $shared_volume_arg \
                jellyfin/jellyfin
            ;;
        rtorrent)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:8080 \
                -p 49160:49160/udp \
                -p 49161:49161 \
                -e TZ="Europe/London" \
                -e USR_ID=1000 \
                -e GRP_ID=1000 \
                -v $config_dir:/downloads \
                diameter/rtorrent-rutorrent:latest
            ;;
        transmission|deluge|qbittorrent|sonarr|radarr|lidarr|prowlarr|jackett|bazarr)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:$port \
                -e TZ="Europe/London" \
                -e PUID=1000 \
                -e PGID=1000 \
                -v $config_dir:/config \
                $shared_volume_arg \
                linuxserver/$name
            ;;
        airsonic)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:4040 \
                -e TZ="Europe/London" \
                -v $config_dir:/airsonic/data \
                -v $shared_media_dir:/airsonic/music \
                airsonic/airsonic
            ;;
        calibre-web)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:8083 \
                -e TZ="Europe/London" \
                -v $config_dir:/config \
                -v $shared_media_dir:/books \
                linuxserver/calibre-web
            ;;
        heimdall)
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:80 \
                -e TZ="Europe/London" \
                -v $config_dir:/config \
                linuxserver/heimdall
            ;;
        *)
            # For other containers, we'll use a generic approach
            # You may need to adjust this for specific containers
            docker run -d \
                --name=$name \
                --restart=unless-stopped \
                -p $port:$port \
                -e TZ="Europe/London" \
                -v $config_dir:/config \
                $shared_volume_arg \
                $name
            ;;
    esac
    echo "$name container started."
}

# Ask user about shared directory
if whiptail --yesno "Do you want to use a shared directory for media?" 8 78; then
    shared_media_dir=$(whiptail --inputbox "Enter the path for the shared media directory:" 8 78 --title "Shared Media Directory" 3>&1 1>&2 2>&3)
    create_directory "$shared_media_dir"
    shared_volume_arg="-v $shared_media_dir:/media"
else
    shared_volume_arg=""
fi

# Create appdata directory in user's home
appdata_dir="$HOME/appdata"
create_directory "$appdata_dir"

# Select media applications
media_options=($(create_checklist "${media_containers[@]}"))
selected_media=$(whiptail --checklist --separate-output \
    "Select media applications:" 20 78 10 \
    "${media_options[@]}" \
    3>&1 1>&2 2>&3)

# If Plex is selected, ask for claim code
if [[ $selected_media == *"plex"* ]]; then
    plex_claim=$(whiptail --inputbox "Enter your Plex claim code:" 8 78 --title "Plex Claim Code" 3>&1 1>&2 2>&3)
fi

# Select torrent downloaders
downloader_options=($(create_checklist "${torrent_downloaders[@]}"))
selected_downloaders=$(whiptail --checklist --separate-output \
    "Select torrent downloaders:" 20 78 10 \
    "${downloader_options[@]}" \
    3>&1 1>&2 2>&3)

# Create configurations and start containers for selected media applications
for name in $selected_media; do
    for container in "${media_containers[@]}"; do
        IFS=':' read -r cname port <<< "$container"
        if [[ "$name" == "$cname" ]]; then
            create_config_and_start "$name" "$port"
            break
        fi
    done
done

# Create configurations and start containers for selected torrent downloaders
for name in $selected_downloaders; do
    for downloader in "${torrent_downloaders[@]}"; do
        IFS=':' read -r cname port <<< "$downloader"
        if [[ "$name" == "$cname" ]]; then
            create_config_and_start "$name" "$port"
            break
        fi
    done
done

whiptail --msgbox "All selected containers have been configured and started. Please check individual container logs for any issues." 8 78