#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Detect the Linux distribution
DISTRO=$(detect_distro)

# Check if whiptail is installed, if not, install it
if ! command_exists whiptail; then
    echo "Installing whiptail..."
    install_packages "$DISTRO" "whiptail"
fi

# Rest of the script functions...

# Call this at the start of the main script execution
install_configure_nginx

# Whiptail menu for package selection...

# Function to install packages based on the distribution
install_packages() {
    local distro="$1"
    shift
    local packages=("$@")

    case "$distro" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y "${packages[@]}"
            ;;
        fedora)
            sudo dnf install -y "${packages[@]}"
            ;;
        centos|rhel)
            sudo yum install -y "${packages[@]}"
            ;;
        arch)
            sudo pacman -Syu --noconfirm "${packages[@]}"
            ;;
        *)
            echo "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
}

# Function to configure rtorrent
configure_rtorrent() {
    mkdir -p ~/rtorrent/{.session,download,watch}
    cat > ~/.rtorrent.rc <<EOL
directory = ~/rtorrent/download
session = ~/rtorrent/.session
schedule = watch_directory,5,5,load.start=~/rtorrent/watch/*.torrent
port_range = 50000-50000
port_random = no
check_hash = yes
dht = auto
peer_exchange = yes
use_udp_trackers = yes
encryption = allow_incoming,try_outgoing,enable_retry
EOL
}

# Function to configure Deluge
configure_deluge() {
    mkdir -p ~/.config/deluge
    cat > ~/.config/deluge/core.conf <<EOL
{
  "download_location": "/home/$USER/deluge/download",
  "torrentfiles_location": "/home/$USER/deluge/torrents",
  "autoadd_location": "/home/$USER/deluge/watch",
  "move_completed_path": "/home/$USER/deluge/completed",
  "plugins_location": "/home/$USER/.config/deluge/plugins",
  "listen_ports": [
    6881,
    6891
  ]
}
EOL
}

# Function to configure qBittorrent
configure_qbittorrent() {
    mkdir -p ~/.config/qBittorrent
    cat > ~/.config/qBittorrent/qBittorrent.conf <<EOL
[Preferences]
Downloads\SavePath=/home/$USER/qbittorrent/downloads
Downloads\TempPath=/home/$USER/qbittorrent/temp
WebUI\Port=8080
EOL
}

# Function to install and configure Plex
install_configure_plex() {
    local distro="$1"
    local claim_token="$2"

    case "$distro" in
        ubuntu|debian)
            curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
            echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
            sudo apt-get update
            sudo apt-get install -y plexmediaserver
            ;;
        fedora|centos|rhel)
            sudo rpm -Uvh https://downloads.plex.tv/plex-media-server-new/1.22.3.4523-d0ce30438/redhat/plexmediaserver-1.22.3.4523-d0ce30438.x86_64.rpm
            ;;
        arch)
            sudo pacman -S plex-media-server
            ;;
        *)
            echo "Unsupported distribution for Plex installation: $distro"
            return
            ;;
    esac

    # Configure Plex with claim token
    sudo systemctl stop plexmediaserver
    sudo sed -i.bak "s/^PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=.*/PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=\/var\/lib\/plexmediaserver\/Library\/Application Support/" /etc/default/plexmediaserver
    sudo -u plex bash -c "export LD_LIBRARY_PATH=/usr/lib/plexmediaserver; /usr/lib/plexmediaserver/Plex\ Media\ Server --claim-server=$claim_token"
    sudo systemctl start plexmediaserver
    echo "Plex Media Server has been installed and configured with the provided claim token."
}

# Function to install and configure Radarr
install_configure_radarr() {
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
    sudo apt-get update
    sudo apt-get install -y mono-devel
    wget https://github.com/Radarr/Radarr/releases/download/v3.2.2.5080/Radarr.master.3.2.2.5080.linux-core-x64.tar.gz
    tar -xvzf Radarr.master.3.2.2.5080.linux-core-x64.tar.gz
    sudo mv Radarr /opt/
    sudo chown -R $USER:$USER /opt/Radarr
    cat > /etc/systemd/system/radarr.service <<EOL
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable radarr.service
    sudo systemctl start radarr.service
}

# Function to install and configure Sonarr
install_configure_sonarr() {
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
    echo "deb https://apt.sonarr.tv/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/sonarr.list
    sudo apt-get update
    sudo apt-get install -y sonarr
}

# Function to install and configure Tautulli
install_configure_tautulli() {
    sudo apt-get install -y python3-pip
    git clone https://github.com/Tautulli/Tautulli.git
    sudo mv Tautulli /opt/
    sudo chown -R $USER:$USER /opt/Tautulli
    cat > /etc/systemd/system/tautulli.service <<EOL
[Unit]
Description=Tautulli - Plex Monitoring
After=network-online.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/usr/bin/python3 /opt/Tautulli/Tautulli.py
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable tautulli.service
    sudo systemctl start tautulli.service
}

# Function to install and configure Ombi
install_configure_ombi() {
    wget https://github.com/Ombi-app/Ombi/releases/latest/download/linux-x64.tar.gz
    tar -xvzf linux-x64.tar.gz
    sudo mv Ombi /opt/
    sudo chown -R $USER:$USER /opt/Ombi
    cat > /etc/systemd/system/ombi.service <<EOL
[Unit]
Description=Ombi
After=network-online.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/opt/Ombi/Ombi
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable ombi.service
    sudo systemctl start ombi.service
}

# Function to install and configure Jackett
install_configure_jackett() {
    wget https://github.com/Jackett/Jackett/releases/download/v0.18.541/Jackett.Binaries.LinuxAMDx64.tar.gz
    tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz
    sudo mv Jackett /opt/
    sudo chown -R $USER:$USER /opt/Jackett
    cat > /etc/systemd/system/jackett.service <<EOL
[Unit]
Description=Jackett Daemon
After=network.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/opt/Jackett/jackett --NoUpdates
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable jackett.service
    sudo systemctl start jackett.service
}
# Function to install and configure Nginx
install_configure_nginx() {
    sudo apt-get install -y nginx

    # Create directories for Nginx configurations
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled

    # Ensure the directories exist in the main Nginx configuration
    if ! grep -q "include /etc/nginx/sites-enabled/\*;" /etc/nginx/nginx.conf; then
        sudo sed -i '/http {/a \    include /etc/nginx/sites-enabled/*.conf;' /etc/nginx/nginx.conf
    fi

    # Configure Nginx for each application
    configure_nginx_for_app "plex" "32400"
    configure_nginx_for_app "radarr" "7878"
    configure_nginx_for_app "sonarr" "8989"
    configure_nginx_for_app "tautulli" "8181"
    configure_nginx_for_app "ombi" "5000"
    configure_nginx_for_app "jackett" "9117"
    configure_nginx_for_app "qbittorrent" "8080"
    configure_nginx_for_app "deluge" "8112"

    # Restart Nginx to apply changes
    sudo systemctl restart nginx
}
# Function to configure Nginx for an application
configure_nginx_for_app() {
    local app_name="$1"
    local app_port="$2"

    cat > "/etc/nginx/sites-available/$app_name" <<EOL
server {
    listen 80;
    server_name $app_name.yourdomain.com;

    location / {
        proxy_pass http://localhost:$app_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

    # Enable the site
    sudo ln -s "/etc/nginx/sites-available/$app_name" "/etc/nginx/sites-enabled/"
}

# Function to install and configure Let's Encrypt SSL
install_configure_letsencrypt() {
    local domain="$1"

    # Install Certbot
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx

    # Obtain and install SSL certificate
    sudo certbot --nginx -d "$domain" --non-interactive --agree-tos --email your@email.com

    # Configure Nginx to use SSL
    sudo sed -i "s/listen 80;/listen 443 ssl;/" "/etc/nginx/sites-available/$domain"
    sudo sed -i "/server_name/a \    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;\n    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;" "/etc/nginx/sites-available/$domain"

    # Restart Nginx to apply changes
    sudo systemctl restart nginx

    echo "SSL certificate has been installed for $domain"
}

# Detect the Linux distribution
DISTRO=$(detect_distro)

# Check if whiptail is installed, if not, install it
if ! command_exists whiptail; then
    echo "Installing whiptail..."
    install_packages "$DISTRO" "whiptail"
fi

# Whiptail menu for package selection (sorted alphabetically)
PACKAGES=$(whiptail --title "Seedbox Installation" --checklist \
"Choose the packages to install:" 20 60 13 \
"deluge" "Deluge" OFF \
"flood" "Flood (rTorrent WebUI)" OFF \
"jackett" "Jackett" OFF \
"letsencrypt" "Let's Encrypt SSL" OFF \
"ombi" "Ombi" OFF \
"plex" "Plex Media Server" OFF \
"qbittorrent" "qBittorrent" OFF \
"radarr" "Radarr" OFF \
"rtorrent" "rTorrent" ON \
"sonarr" "Sonarr" OFF \
"tautulli" "Tautulli" OFF \
"transmission" "Transmission" OFF 3>&1 1>&2 2>&3)

# Exit if user cancels
if [ $? -ne 0 ]; then
    echo "Installation cancelled."
    exit 1
fi

# Convert the result to an array
IFS=' ' read -r -a selected_packages <<< "$PACKAGES"

# Install Nginx
install_configure_nginx

# Initialize an array to store installed packages and their URLs/ports
declare -A installed_services

# Install selected packages
for package in "${selected_packages[@]}"; do
    package=$(echo "$package" | tr -d '"')
    echo "Installing $package..."
    
    case "$package" in
        rtorrent)
            install_packages "$DISTRO" "rtorrent"
            configure_rtorrent
            installed_services["rtorrent"]="Port: 50000"
            ;;
        deluge)
            install_packages "$DISTRO" "deluge"
            configure_deluge
            installed_services["deluge"]="http://localhost:8112"
            ;;
        transmission)
            install_packages "$DISTRO" "transmission-daemon"
            installed_services["transmission"]="http://localhost:9091"
            ;;
        qbittorrent)
            install_packages "$DISTRO" "qbittorrent-nox"
            configure_qbittorrent
            installed_services["qbittorrent"]="http://localhost:8080"
            ;;
        flood)
            if command_exists npm; then
                sudo npm install -g flood
                installed_services["flood"]="http://localhost:3000"
            else
                echo "npm is required to install Flood. Please install Node.js and npm first."
            fi
            ;;
        plex)
            PLEX_CLAIM=$(whiptail --inputbox "Enter your Plex claim token (https://www.plex.tv/claim/):" 8 78 --title "Plex Claim Token" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then
                echo "Plex installation cancelled."
            else
                install_configure_plex "$DISTRO" "$PLEX_CLAIM"
                installed_services["plex"]="http://localhost:32400/web"
            fi
            ;;
        radarr)







