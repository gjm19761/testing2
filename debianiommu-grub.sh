#!/bin/bash

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

# Backup the GRUB configuration file
cp /etc/default/grub /etc/default/grub.backup

# Add Intel IOMMU option to GRUB_CMDLINE_LINUX_DEFAULT
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 intel_iommu=on"/' /etc/default/grub
else
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on"' >> /etc/default/grub
fi

# Update GRUB
update-grub

echo "Intel IOMMU has been enabled in GRUB configuration."
echo "Please reboot your system for the changes to take effect."
