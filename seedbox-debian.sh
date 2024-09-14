#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages
install_packages() {
    sudo apt-get update
    sudo apt-get install -y "$@"
}

# Install and configure Nginx
install_configure_nginx() {
    install_packages nginx
    
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled

    if ! grep -q "include /etc/nginx/sites-enabled/\*;" /etc/nginx/nginx.conf; then
        sudo sed -i '/http {/a \    include /etc/nginx/sites-enabled/*.conf;' /etc/nginx/nginx.conf
    fi

    sudo systemctl restart nginx
}

# Function to configure Nginx for an application
configure_nginx_for_app() {
    local app_name="$1"
    local app_port="$2"

    sudo tee "/etc/nginx/sites-available/$app_name.conf" > /dev/null <<EOL
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

    sudo ln -sf "/etc/nginx/sites-available/$app_name.conf" "/etc/nginx/sites-enabled/"
}

# Install and configure Let's Encrypt
install_letsencrypt() {
    install_packages certbot python3-certbot-nginx

    local domain
    domain=$(whiptail --inputbox "Enter your domain name:" 8 78 --title "Domain for SSL" 3>&1 1>&2 2>&3)

    if [ -z "$domain" ]; then
        echo "Domain name is required. Skipping Let's Encrypt configuration."
        return
    fi

    sudo certbot --nginx -d "$domain" --non-interactive --agree-tos --email your@email.com

    # Update Nginx configurations to use SSL
    for conf in /etc/nginx/sites-available/*.conf; do
        sudo sed -i "s/listen 80;/listen 443 ssl http2;\\n    listen 80;\\n    if (\$scheme != \"https\") {\\n        return 301 https://\$server_name\$request_uri;\\n    }/" "$conf"
        sudo sed -i "/server_name/a \    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;\n    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;" "$conf"
    done

    sudo systemctl restart nginx

    echo "SSL certificates have been installed for $domain"
}

# Install and configure applications
install_deluge() {
    install_packages deluge deluged deluge-web
    configure_nginx_for_app "deluge" "8112"
    echo "Deluge installed. URL: http://localhost:8112"
}

install_plex() {
    local plex_claim
    plex_claim=$(whiptail --inputbox "Enter your Plex claim code (https://www.plex.tv/claim/):" 8 78 --title "Plex Claim Code" 3>&1 1>&2 2>&3)
    
    wget https://downloads.plex.tv/plex-media-server-new/1.32.5.7349-8f4248874/debian/plexmediaserver_1.32.5.7349-8f4248874_amd64.deb
    sudo dpkg -i plexmediaserver*.deb
    rm plexmediaserver*.deb
    
    # Stop Plex service
    sudo systemctl stop plexmediaserver

    # Set claim token
    sudo sed -i "s/PLEX_CLAIM=\"\"/PLEX_CLAIM=\"$plex_claim\"/" /etc/default/plexmediaserver

    # Start Plex service
    sudo systemctl start plexmediaserver
    
    configure_nginx_for_app "plex" "32400"
    echo "Plex installed. URL: http://localhost:32400/web"
}

install_radarr() {
    install_packages libmono-cil-dev curl mediainfo
    wget https://github.com/Radarr/Radarr/releases/download/v4.3.2.6857/Radarr.master.4.3.2.6857.linux-core-x64.tar.gz
    tar -xvzf Radarr.master*.tar.gz
    sudo mv Radarr /opt/
    sudo tee /etc/systemd/system/radarr.service > /dev/null <<EOL
[Unit]
Description=Radarr Daemon
After=network.target

[Service]
User=$USER
ExecStart=/opt/Radarr/Radarr -nobrowser
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable radarr
    sudo systemctl start radarr
    configure_nginx_for_app "radarr" "7878"
    echo "Radarr installed. URL: http://localhost:7878"
}

install_sonarr() {
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
    echo "deb https://apt.sonarr.tv/debian buster main" | sudo tee /etc/apt/sources.list.d/sonarr.list
    install_packages sonarr
    configure_nginx_for_app "sonarr" "8989"
    echo "Sonarr installed. URL: http://localhost:8989"
}

install_jackett() {
    install_packages libicu-dev
    wget https://github.com/Jackett/Jackett/releases/download/v0.20.3200/Jackett.Binaries.LinuxAMDx64.tar.gz
    tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz
    sudo mv Jackett /opt/
    sudo tee /etc/systemd/system/jackett.service > /dev/null <<EOL
[Unit]
Description=Jackett Daemon
After=network.target

[Service]
User=$USER
ExecStart=/opt/Jackett/jackett --NoUpdates
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable jackett
    sudo systemctl start jackett
    configure_nginx_for_app "jackett" "9117"
    echo "Jackett installed. URL: http://localhost:9117"
}

install_ombi() {
    wget https://github.com/Ombi-app/Ombi/releases/latest/download/linux-x64.tar.gz
    tar -xvzf linux-x64.tar.gz
    sudo mv Ombi /opt/
    sudo tee /etc/systemd/system/ombi.service > /dev/null <<EOL
[Unit]
Description=Ombi Service
After=network.target

[Service]
User=$USER
ExecStart=/opt/Ombi/Ombi
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable ombi
    sudo systemctl start ombi
    configure_nginx_for_app "ombi" "5000"
    echo "Ombi installed. URL: http://localhost:5000"
}

install_tautulli() {
    sudo apt-get install python3-pip
    git clone https://github.com/Tautulli/Tautulli.git
    sudo mv Tautulli /opt/
    sudo tee /etc/systemd/system/tautulli.service > /dev/null <<EOL
[Unit]
Description=Tautulli Service
After=network.target

[Service]
User=$USER
ExecStart=/usr/bin/python3 /opt/Tautulli/Tautulli.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable tautulli
    sudo systemctl start tautulli
    configure_nginx_for_app "tautulli" "8181"
    echo "Tautulli installed. URL: http://localhost:8181"
}

install_rtorrent_rutorrent() {
    install_packages rtorrent
    sudo apt-get install php-fpm php-cli php-json php-curl php-geoip
    git clone https://github.com/Novik/ruTorrent.git
    sudo mv ruTorrent /var/www/
    sudo chown -R www-data:www-data /var/www/ruTorrent
    configure_nginx_for_app "rutorrent" "80"
    echo "rTorrent with ruTorrent installed. URL: http://localhost/rutorrent"
}

install_qbittorrent() {
    install_packages qbittorrent-nox
    sudo tee /etc/systemd/system/qbittorrent.service > /dev/null <<EOL
[Unit]
Description=qBittorrent Daemon Service
After=network.target

[Service]
User=$USER
ExecStart=/usr/bin/qbittorrent-nox
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl enable qbittorrent
    sudo systemctl start qbittorrent
    configure_nginx_for_app "qbittorrent" "8080"
    echo "qBittorrent installed. URL: http://localhost:8080"
}

install_transmission() {
    install_packages transmission-daemon
    configure_nginx_for_app "transmission" "9091"
    echo "Transmission installed. URL: http://localhost:9091"
}

# Check if whiptail is installed, if not, install it
if ! command_exists whiptail; then
    echo "Installing whiptail..."
    install_packages whiptail
fi

# Set Whiptail colors
export NEWT_COLORS='
root=,black
window=green,black
border=green,black
textbox=green,black
button=black,green
'

# Whiptail menu for package selection (sorted alphabetically)
PACKAGES=$(whiptail --title "Seedbox Installation" --checklist \
"Choose the packages to install:" 20 60 12 \
"deluge" "Deluge" OFF \
"jackett" "Jackett" OFF \
"letsencrypt" "Let's Encrypt SSL" OFF \
"ombi" "Ombi" OFF \
"plex" "Plex Media Server" OFF \
"qbittorrent" "qBittorrent" OFF \
"radarr" "Radarr" OFF \
"rtorrent" "rTorrent with ruTorrent" OFF \
"sonarr" "Sonarr" OFF \
"tautulli" "Tautulli" OFF \
"transmission" "Transmission" OFF 3>&1 1>&2 2>&3)

# Exit if user cancels
if [ $? -ne 0 ]; then
    echo "Installation cancelled."
    exit 1
fi

# Install Nginx
install_configure_nginx

# Initialize an array to store installed apps and their URLs
declare -A installed_apps

# Install selected packages
for package in $PACKAGES; do
    package=$(echo "$package" | tr -d '"')
    echo "Installing $package..."
    
    case "$package" in
        deluge) 
            install_deluge
            installed_apps["Deluge"]="http://localhost:8112"
            ;;
        jackett) 
            install_jackett
            installed_apps["Jackett"]="http://localhost:9117"
            ;;
        letsencrypt) 
            install_letsencrypt
            ;;
        ombi) 
            install_ombi
            installed_apps["Ombi"]="http://localhost:5000"
            ;;
        plex) 
            install_plex
            installed_apps["Plex"]="http://localhost:32400/web"
            ;;
        qbittorrent) 
            install_qbittorrent
            installed_apps["qBittorrent"]="http://localhost:8080"
            ;;
        radarr) 
            install_radarr
            installed_apps["Radarr"]="http://localhost:7878"
            ;;
        rtorrent) 
            install_rtorrent_rutorrent
            installed_apps["ruTorrent"]="http://localhost/rutorrent"
            ;;
        sonarr) 
            install_sonarr
            installed_apps["Sonarr"]="http://localhost:8989"
            ;;
        tautulli) 
            install_tautulli
            installed_apps["Tautulli"]="http://localhost:8181"
            ;;
        transmission) 
            install_transmission
            installed_apps["Transmission"]="http://localhost:9091"
            ;;
    esac
done

# Restart Nginx to apply all changes
sudo systemctl restart nginx

echo "Installation complete. Here are the URLs for the installed applications:"
for app in "${!installed_apps[@]}"; do
    echo "$app: ${installed_apps[$app]}"
done

echo "Please configure each application as needed."




