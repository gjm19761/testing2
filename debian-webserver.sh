#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ask for server name
echo -e "${BLUE}Enter your server name (e.g., example.com):${NC} "
read SERVER_NAME

# Ask if SSL certificate is desired
echo -e "${BLUE}Do you want to install an SSL certificate from Let's Encrypt? (y/n):${NC} "
read INSTALL_SSL

# Check if Nginx is already installed
if ! command -v nginx &> /dev/null
then
    echo -e "${YELLOW}Nginx not found. Installing Nginx...${NC}"
    sudo apt-get update
    sudo apt-get install -y nginx
else
    echo -e "${GREEN}Nginx is already installed.${NC}"
fi

# Add www-data user and group if they don't exist
if ! id -u www-data &>/dev/null; then
    echo -e "${YELLOW}Adding www-data user and group...${NC}"
    sudo useradd -r -s /sbin/nologin www-data
    sudo groupadd www-data
    sudo usermod -a -G www-data www-data
else
    echo -e "${GREEN}www-data user already exists.${NC}"
fi

# Create /var/www directory if it doesn't exist
if [ ! -d "/var/www" ]; then
    echo -e "${YELLOW}Creating /var/www directory...${NC}"
    sudo mkdir -p /var/www
    sudo chown www-data:www-data /var/www
else
    echo -e "${GREEN}/var/www directory already exists. Ensuring correct ownership...${NC}"
    sudo chown www-data:www-data /var/www
fi

# Configure Nginx
echo -e "${YELLOW}Configuring Nginx...${NC}"
sudo tee /etc/nginx/sites-available/$SERVER_NAME > /dev/null << EOL
server {
    listen 80;
    listen [::]:80;

    root /var/www;
    index index.html index.htm index.nginx-debian.html;

    server_name $SERVER_NAME;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Enable the new configuration
sudo ln -sf /etc/nginx/sites-available/$SERVER_NAME /etc/nginx/sites-enabled/

# Remove default configuration if it exists
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
sudo nginx -t

# Restart Nginx
echo -e "${YELLOW}Restarting Nginx...${NC}"
sudo systemctl restart nginx

# Install SSL certificate if requested
if [[ "$INSTALL_SSL" =~ ^[Yy]$ ]]; then
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}Installing Let's Encrypt SSL certificate...${NC}"
        sudo apt-get install -y certbot python3-certbot-nginx
    fi
    sudo certbot --nginx -d $SERVER_NAME
    
    # Adjust Nginx configuration for SSL
    echo -e "${YELLOW}Adjusting Nginx configuration for SSL...${NC}"
    sudo tee /etc/nginx/sites-available/$SERVER_NAME > /dev/null << EOL
server {
    listen 80;
    listen [::]:80;
    server_name $SERVER_NAME;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    root /var/www;
    index index.html index.htm index.nginx-debian.html;

    server_name $SERVER_NAME;

    ssl_certificate /etc/letsencrypt/live/$SERVER_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$SERVER_NAME/privkey.pem;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

    # Restart Nginx to apply SSL changes
    echo -e "${YELLOW}Restarting Nginx to apply SSL changes...${NC}"
    sudo systemctl restart nginx
fi

echo -e "${GREEN}Nginx setup complete!${NC}"
echo -e "${BLUE}Your web content should be placed in /var/www${NC}"
echo -e "${BLUE}Nginx is now serving content for $SERVER_NAME${NC}"
if [[ "$INSTALL_SSL" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}SSL certificate has been installed and configured${NC}"
fi



