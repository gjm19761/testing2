#!/bin/bash

# Function to prompt for yes/no confirmation
confirm() {
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to check if a package is installed
is_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

# Check and install Samba if not already installed
if ! is_installed samba; then
    echo "Installing Samba..."
    sudo apt-get update
    sudo apt-get install -y samba
else
    echo "Samba is already installed."
fi

# Prompt for server name
read -p "Enter a name for this server: " server_name

# Prompt for directory to share
read -p "Enter the directory path you want to share: " share_dir

# Validate directory
if [ ! -d "$share_dir" ]; then
    echo "Directory does not exist. Creating it..."
    sudo mkdir -p "$share_dir"
fi

# Prompt for share name
read -p "Enter a name for this share: " share_name

# Prompt for guest access
if confirm "Allow guest access?"; then
    guest_ok="yes"
else
    guest_ok="no"
fi

# Prompt for write access
if confirm "Allow write access?"; then
    writable="yes"
else
    writable="no"
fi

# Prompt for Avahi installation
if confirm "Do you want to install Avahi for network discovery?"; then
    if ! is_installed avahi-daemon; then
        echo "Installing Avahi..."
        sudo apt-get install -y avahi-daemon
        sudo systemctl enable avahi-daemon
        sudo systemctl start avahi-daemon
    else
        echo "Avahi is already installed."
    fi
fi

# Add configuration to smb.conf
echo "Adding share to Samba configuration..."
sudo tee -a /etc/samba/smb.conf > /dev/null << EOL

[global]
   netbios name = $server_name
   server string = $server_name

[$share_name]
   path = $share_dir
   guest ok = $guest_ok
   read only = no
   writable = $writable
EOL

# Restart Samba service
echo "Restarting Samba service..."
sudo systemctl restart smbd

echo "Samba share setup complete!"
echo "Server Name: $server_name"
echo "Share Name: $share_name"
echo "Share Path: $share_dir"
echo "Guest Access: $guest_ok"
echo "Writable: $writable"
if is_installed avahi-daemon; then
    echo "Avahi is installed for network discovery"
fi
