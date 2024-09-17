#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install Nginx, PHP, and MySQL
sudo apt install -y nginx php-fpm php-mysql mysql-server

# Start and enable services
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start mysql
sudo systemctl enable mysql

# Configure PHP-FPM
sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.4/fpm/php.ini
sudo systemctl restart php7.4-fpm

# Create web root directory
sudo mkdir -p /var/www/html

# Set proper permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Prompt for domain name
read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME

# Configure Nginx for PHP processing
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
EOF

# Enable the default site
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# If test is successful, reload Nginx
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "Nginx configuration has been updated and reloaded."
else
    echo "Nginx configuration test failed. Please check your configuration."
fi

# Create a sample PHP file to test
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

# Set MySQL root password
MYSQL_ROOT_PASSWORD="default"

# Secure MySQL installation
sudo mysql --user=root <<_EOF_
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_

# Ask if user wants to install phpMyAdmin
read -p "Do you want to install phpMyAdmin? (y/n): " INSTALL_PHPMYADMIN

if [ "$INSTALL_PHPMYADMIN" = "y" ]; then
    sudo apt install -y phpmyadmin php-mbstring php-zip php-gd php-json php-curl
    sudo phpenmod mbstring
    sudo systemctl restart php7.4-fpm
    echo "phpMyAdmin installed and configured."
fi

# Ask if user wants SSL via Let's Encrypt
read -p "Do you want to set up SSL using Let's Encrypt? (y/n): " SETUP_SSL

if [ "$SETUP_SSL" = "y" ]; then
    # Install Certbot
    sudo apt install -y certbot python3-certbot-nginx

    # Obtain and install SSL certificate
    sudo certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME

    # Configure Nginx for SSL
    sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    root /var/www/html;
    index index.php index.html index.htm;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
EOF

    sudo nginx -t && sudo systemctl reload nginx
    echo "SSL certificate installed and Nginx configured for HTTPS."
fi

echo "Setup complete. Your web server is now configured to serve PHP scripts with MySQL support."
echo "You can add more sites by creating new server blocks in /etc/nginx/sites-available/ and linking them to /etc/nginx/sites-enabled/"
echo "MySQL root password has been set to 'default'. Please change this in a production environment."
echo "Remember to secure your server in a production environment."



