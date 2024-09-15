#!/bin/bash

set -x  # Enable debug mode

# Function to create directory if it doesn't exist
create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Created directory: $1"
    fi
}

<<<<<<< Updated upstream
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
=======
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
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
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
=======
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
media_options=$(create_checklist "${media_containers[@]}")
selected_media=$(whiptail --checklist --separate-output \
    "Select media applications:" 20 78 10 \
    ${media_options} \
    3>&1 1>&2 2>&3)

# If Plex is selected, ask for claim code
if [[ $selected_media == *"plex"* ]]; then
    plex_claim=$(whiptail --inputbox "Enter your Plex claim code:" 8 78 --title "Plex Claim Code" 3>&1 1>&2 2>&3)
fi

# Select torrent downloaders
downloader_options=$(create_checklist "${torrent_downloaders[@]}")
selected_downloaders=$(whiptail --checklist --separate-output \
    "Select torrent downloaders:" 20 78 10 \
    ${downloader_options} \
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
>>>>>>> Stashed changes
