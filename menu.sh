#!/bin/bash

# Function to display the main menu
show_main_menu() {
    local choice
    choice=$(whiptail --title "Main Menu" --menu "Choose an option:" 15 60 6 \
        "1" "Install All" \
        "2" "Base packages" \
        "3" "Mirrorlist" \
        "4" "Install Firmware" \
        "5" "Updates" \
        "6" "Exit" 3>&1 1>&2 2>&3)

    case $choice in
        1) install_all ;;
        2) install_base_packages ;;
        3) update_mirrorlist ;;
        4) install_firmware ;;
        5) update_packages ;;
        6) exit 0 ;;
        *) show_main_menu ;;
    esac
}

# Function to install all components
install_all() {
    update_packages
    install_base
    update_mirrorlist
    install_firmware
    enable_multilib
    enable_sudo_insults
    stylize_pacman
    parallelize_pacman
    disable_beep
    whiptail --title "Installation Complete" --msgbox "All components have been installed." 8 78
    show_main_menu
}

# Function to install base packages
install_base_packages() {
    install_base
    whiptail --title "Base Packages" --msgbox "Base packages have been installed." 8 78
    show_main_menu
}

# Main loop
while true; do
    show_main_menu
done
