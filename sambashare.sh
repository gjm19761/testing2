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

# Install Samba
echo "Installing Samba..."
sudo apt-get update
sudo apt-get install -y samba

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

# Add configuration to smb.conf
echo "Adding share to Samba configuration..."
sudo tee -a /etc/samba/smb.conf > /dev/null << EOL

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
echo "Share Name: $share_name"
echo "Share Path: $share_dir"
echo "Guest Access: $guest_ok"
echo "Writable: $writable"
