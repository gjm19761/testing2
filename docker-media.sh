#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

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
    create_directory "$config_dir"
    
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

# Arrays of media containers and torrent downloaders
media_containers=(
    "plex:32400" "emby:8096" "jellyfin:8920" "kodi:8080" "airsonic:4040"
)

torrent_downloaders=(
    "transmission:9091" "deluge:8112" "qbittorrent:8080"
)

# Get shared media directory
read -p "Enter the path for the shared media directory: " shared_media_dir
create_directory "$shared_media_dir"

# Create appdata directory
appdata_dir="$HOME/appdata"
create_directory "$appdata_dir"

# Select media applications
echo "Selecting media applications..."
media_names=($(printf "%s\n" "${media_containers[@]}" | cut -d':' -f1))
selected_media=$(display_menu "Select Media Applications" "${media_names[@]}")

# Select torrent downloaders
echo "Selecting torrent downloaders..."
downloader_names=($(printf "%s\n" "${torrent_downloaders[@]}" | cut -d':' -f1))
selected_downloaders=$(display_menu "Select Torrent Downloaders" "${downloader_names[@]}")

# Create Docker network
create_docker_network

# Create Docker Compose files and start containers
echo "Creating Docker Compose files and starting containers..."
for container in $selected_media $selected_downloaders; do
    port=$(echo "${media_containers[@]} ${torrent_downloaders[@]}" | tr ' ' '\n' | grep "^$container:" | cut -d':' -f2)
    create_docker_compose "$container" "$port"
    (cd "$appdata_dir/$container" && docker-compose up -d)
done

echo "All selected containers have been configured and started."
echo "Please check individual container logs for any issues."