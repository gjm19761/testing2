#!/bin/bash

# Function to detect graphics hardware
detect_graphics() {
    if lspci | grep -i "VGA compatible controller: NVIDIA" > /dev/null; then
        echo "NVIDIA"
    elif lspci | grep -i "VGA compatible controller: Advanced Micro Devices" > /dev/null; then
        echo "AMD"
    elif lspci | grep -i "VGA compatible controller: Intel" > /dev/null; then
        echo "Intel"
    else
        echo "Unknown"
    fi
}

# Detect graphics hardware
GRAPHICS=$(detect_graphics)

echo "Detected graphics: $GRAPHICS"

# Configure kernel and install drivers based on detected hardware
case $GRAPHICS in
    "NVIDIA")
        echo "Configuring for NVIDIA graphics..."
        # Add NVIDIA driver repository
        sudo add-apt-repository ppa:graphics-drivers/ppa -y
        sudo apt update
        # Install NVIDIA driver (you may want to specify a version)
        sudo apt install nvidia-driver-460 -y
        # Update kernel parameters for NVIDIA
        echo "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia-drm-nomodeset.conf
        ;;
    "AMD")
        echo "Configuring for AMD graphics..."
        # Install AMD driver
        sudo apt install mesa-vulkan-drivers xserver-xorg-video-amdgpu -y
        ;;
    "Intel")
        echo "Configuring for Intel graphics..."
        # Install Intel drivers for integrated graphics
        sudo apt update
        sudo apt install -y intel-microcode
        sudo apt install -y linux-generic-hwe-20.04 # For Ubuntu 20.04, adjust if using a different version
        sudo apt install -y mesa-utils
        sudo apt install -y libgl1-mesa-dri libgl1-mesa-glx
        sudo apt install -y va-driver-all i965-va-driver intel-media-va-driver
        sudo apt install -y intel-gpu-tools
        
        # Ensure i915 driver is loaded
        echo "i915" | sudo tee -a /etc/modules
        
        # Configure kernel parameters for Intel graphics
        echo "options i915 modeset=1" | sudo tee -a /etc/modprobe.d/i915.conf
        ;;
    *)
        echo "Unknown graphics hardware. Unable to configure."
        exit 1
        ;;
esac

# Update initramfs to include the i915 driver (for Intel) or other changes
sudo update-initramfs -u

echo "Graphics configuration complete. The i915 driver has been added to the kernel modules (for Intel graphics)."
echo "Please reboot your system for changes to take effect."


