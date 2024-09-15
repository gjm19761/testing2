#!/bin/bash

# Function to check if Docker is installed and install if not
check_docker_install() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        echo "Docker installed successfully. Please log out and log back in to use Docker without sudo."
        exit 0
    else
        echo "Docker is already installed."
    fi
}

# Function to create directory if it doesn't exist
create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Created directory: $1"
    fi
}

# Check and install Docker
check_docker_install

# Ask user about shared directory
if whiptail --yesno "Do you want to use a shared directory for media?" 8 78; then
    shared_media_dir=$(whiptail --inputbox "Enter the path for the shared media directory:" 8 78 "/path/to/media" --title "Shared Media Directory" 3>&1 1>&2 2>&3)
    create_directory "$shared_media_dir"
    shared_volume_arg="-v $shared_media_dir:/media"
else
    shared_volume_arg=""
fi

# Create appdata directory in user's home
appdata_dir="$HOME/appdata"
create_directory "$appdata_dir"

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

# Create whiptail menu for media containers
media_options=()
for container in "${media_containers[@]}"; do
    IFS=':' read -r name port <<< "$container"
    media_options+=("$name" "" OFF)
done

selected_media=$(whiptail --title "Select Media Applications" --checklist \
"Choose the media applications you want to install:" 20 78 15 \
"${media_options[@]}" \
3>&1 1>&2 2>&3)

# Create whiptail menu for torrent downloaders
torrent_options=()
for downloader in "${torrent_downloaders[@]}"; do
    IFS=':' read -r name port <<< "$downloader"
    torrent_options+=("$name" "" OFF)
done

selected_torrent=$(whiptail --title "Select Torrent Downloaders" --checklist \
"Choose the torrent downloaders you want to install:" 20 78 10 \
"${torrent_options[@]}" \
3>&1 1>&2 2>&3)

# Install selected media containers
for container in $selected_media; do
    echo "Installing $container..."
    for item in "${media_containers[@]}"; do
        IFS=':' read -r name port <<< "$item"
        if [ "$name" == "$container" ]; then
            config_dir="$appdata_dir/$container"
            create_directory "$config_dir"
            case $container in
                "plex")
                    docker run -d \
                        --name=plex \
                        --restart=unless-stopped \
                        -v $config_dir:/config \
                        $shared_volume_arg \
                        -p $port:32400 \
                        -e PLEX_CLAIM="claim-xxxxxxxxxxxxxxxxxxxx" \
                        plexinc/pms-docker
                    ;;
                "emby")
                    docker run -d \
                        --name=emby \
                        --restart=unless-stopped \
                        -v $config_dir:/config \
                        $shared_volume_arg \
                        -p $port:8096 \
                        emby/embyserver
                    ;;
                "jellyfin")
                    docker run -d \
                        --name=jellyfin \
                        --restart=unless-stopped \
                        -v $config_dir:/config \
                        $shared_volume_arg \
                        -p $port:8096 \
                        jellyfin/jellyfin
                    ;;
                *)
                    docker run -d \
                        --name=$container \
                        --restart=unless-stopped \
                        -v $config_dir:/config \
                        $shared_volume_arg \
                        -p $port:$port \
                        linuxserver/$container
                    ;;
            esac
            break
        fi
    done
done

# Install selected torrent downloaders
for downloader in $selected_torrent; do
    echo "Installing $downloader..."
    for item in "${torrent_downloaders[@]}"; do
        IFS=':' read -r name port <<< "$item"
        if [ "$name" == "$downloader" ]; then
            config_dir="$appdata_dir/$downloader"
            create_directory "$config_dir"
            case $downloader in
                "transmission")
                    docker run -d \
                        --name=transmission \
                        --restart=unless-stopped \
                        -v $config_dir:/config \
                        $shared_volume_arg \
                        -p $port:9091 \
                        -p 51413:51413 \
                        -p 51413:51413/udp \
                        linuxserver/transmission
                    ;;
                "deluge")
                    docker run -d \
                        --name=deluge \
                        --restart=unless-stopped \
                        -v $config_dir:/config \
                        $shared_volume_arg \
                        -p $port:8112 \
                        -p 58846:58846 \
                        -p 58946:58946 \
                        linuxserver/deluge
                    ;;
                "qbittorrent")
                    docker run -d \
                        --name=qbittorrent \
                        --restart=unless-stopped \
                        -v $config_dir:/config \
                        $shared_volume_arg \
                        -p $port:8080 \
                        -p 6881:6881 \
                        -p 6881:6881/udp \
                        linuxserver/qbittorrent
                    ;;
                *)
                    docker run -d \
                        --name=$downloader \
                        --restart=unless-stopped \
                        -v $config_dir:/config \
                        $shared_volume_arg \
                        -p $port:$port \
                        linuxserver/$downloader
                    ;;
            esac
            break
        fi
    done
done

echo "Installation complete. Please check individual container logs for any issues."




