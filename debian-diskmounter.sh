#!/bin/bash

# Function to get list of unmounted disks
get_unmounted_disks() {
    lsblk -nrpo NAME,TYPE,MOUNTPOINT | awk '$2=="disk" && $3==""' | cut -d' ' -f1
}

# Function to create a directory if it doesn't exist
create_directory() {
    if [ ! -d "$1" ]; then
        if ! mkdir -p "$1" 2>/dev/null; then
            sudo mkdir -p "$1"
        fi
        echo "Created directory: $1"
    fi
}

# Get list of unmounted disks
unmounted_disks=($(get_unmounted_disks))

if [ ${#unmounted_disks[@]} -eq 0 ]; then
    whiptail --msgbox "No unmounted disks found." 10 50
    exit 0
fi

# Prepare disk options for whiptail
disk_options=()
for disk in "${unmounted_disks[@]}"; do
    disk_options+=("$disk" "")
done

# Show disk selection dialog
selected_disk=$(whiptail --title "Select Disk to Mount" --menu "Choose a disk to mount:" 15 60 5 "${disk_options[@]}" 3>&1 1>&2 2>&3)

if [ -z "$selected_disk" ]; then
    echo "No disk selected. Exiting."
    exit 0
fi

# Ask for mount point
mount_point=$(whiptail --inputbox "Enter the mount point for $selected_disk:" 10 60 "/mnt/mydisk" 3>&1 1>&2 2>&3)

if [ -z "$mount_point" ]; then
    echo "No mount point specified. Exiting."
    exit 0
fi

# Create the mount point directory
create_directory "$mount_point"

# Get the UUID of the selected disk
uuid=$(sudo blkid -s UUID -o value "$selected_disk")

if [ -z "$uuid" ]; then
    echo "Failed to get UUID for $selected_disk. Exiting."
    exit 1
fi

# Add entry to fstab
echo "UUID=$uuid $mount_point auto defaults 0 0" | sudo tee -a /etc/fstab

# Mount the disk
sudo mount "$mount_point"

if [ $? -eq 0 ]; then
    whiptail --msgbox "Disk $selected_disk has been mounted to $mount_point and added to fstab." 10 60
else
    whiptail --msgbox "Failed to mount $selected_disk. Please check the disk and try again." 10 60
fi

