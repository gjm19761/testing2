
#!/bin/bash

# Function to get list of unmounted partitions
get_unmounted_partitions() {
    lsblk -nrpo NAME,TYPE,MOUNTPOINT | awk '$2=="part" && $3==""' | cut -d' ' -f1
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

# Get list of unmounted partitions
unmounted_partitions=($(get_unmounted_partitions))

if [ ${#unmounted_partitions[@]} -eq 0 ]; then
    whiptail --msgbox "No unmounted partitions found." 10 50
    exit 0
fi

# Prepare partition options for whiptail
partition_options=()
for partition in "${unmounted_partitions[@]}"; do
    partition_options+=("$partition" "")
done

# Show partition selection dialog
selected_partition=$(whiptail --title "Select Partition to Mount" --menu "Choose a partition to mount:" 15 60 5 "${partition_options[@]}" 3>&1 1>&2 2>&3)

if [ -z "$selected_partition" ]; then
    echo "No partition selected. Exiting."
    exit 0
fi

# Ask for mount point
mount_point=$(whiptail --inputbox "Enter the mount point for $selected_partition:" 10 60 "/mnt/mypartition" 3>&1 1>&2 2>&3)

if [ -z "$mount_point" ]; then
    echo "No mount point specified. Exiting."
    exit 0
fi

# Create the mount point directory
create_directory "$mount_point"

# Get the UUID of the selected partition
uuid=$(sudo blkid -s UUID -o value "$selected_partition")

if [ -z "$uuid" ]; then
    # If UUID is not available, use the partition name instead
    echo "UUID not found for $selected_partition. Using partition name in fstab."
    fstab_entry="$selected_partition $mount_point auto defaults 0 0"
else
    fstab_entry="UUID=$uuid $mount_point auto defaults 0 0"
fi

# Add entry to fstab
echo "$fstab_entry" | sudo tee -a /etc/fstab

# Mount the partition
sudo mount "$mount_point"

if [ $? -eq 0 ]; then
    whiptail --msgbox "Partition $selected_partition has been mounted to $mount_point and added to fstab." 10 60
else
    whiptail --msgbox "Failed to mount $selected_partition. Please check the partition and try again." 10 60
fi
