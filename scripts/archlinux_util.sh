#!/bin/sh
#-----------------------------------------------------------------------------------------------------------------
# Copyright (c) Bart Venter.
# Licensed under the MIT License. See https://github.com/bartventer/devcontainer-features for license information.
#-----------------------------------------------------------------------------------------------------------------
#
# Maintainer: Bart Venter <https://github.com/bartventer>
#
# Description:  This utility script, `archlinux_util.sh`, performs common checks for Arch-based systems and 
#               facilitates consistent usage of the pacman package manager. It also provides functions for 
#               adjusting directory permissions  and installing packages. This script is intended to be used as a 
#               utility helper when setting up and managing Arch Linux systems in devcontainer features.
# 
#-----------------------------------------------------------------------------------------------------------------


# Exit on error
set -e

DIR_PERMS_CHECKED="${DIR_PERMS_CHECKED:-false}"
KEYRING_CHECKED="${KEYRING_CHECKED:-false}"

# Echo message
echo_msg() {
    old_message=$message
    message=$1
    echo "[devcontainer-features/scripts/archlinux] ${message}"
    message=$old_message
}

# Checks if script is run as root
check_root() {
    echo_msg "Checking if script is run as root..."
    if [ "$(id -u)" -ne 0 ]; then
        printf 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.\n'
        exit 1
    fi
    echo_msg "OK. Script is run as root."
}

# Checks if we're on an Arch-based system
check_system() {
    echo_msg "Checking Arch-based system..."
    if ! grep -q 'ID=arch' /etc/os-release; then
        echo "This script is intended for Arch-based systems. Please run this script on an Arch-based system."
        exit 1
    fi
    echo_msg "OK. On an Arch-based system."
}

# Checks if pacman is installed
check_pacman() {
    echo_msg "Checking if pacman is installed..."
    if ! command -v pacman > /dev/null 2>&1; then
        echo "Pacman could not be found. Please install pacman and try again."
        exit 1
    fi
    echo_msg "OK. Pacman is installed."
}

# Initialize pacman keyring
init_pacman_keyring() {
    if [ "$KEYRING_CHECKED" = false ]; then
        echo_msg "Initializing pacman keyring (current count: $(pacman-key --list-keys | wc -l))..."
        if pacman-key --init && pacman-key --populate archlinux; then
            echo_msg "OK. Pacman keyring initialized (new count: $(pacman-key --list-keys | wc -l))."
            export KEYRING_CHECKED=true
        else
            echo_msg "ERROR. Pacman keyring initialization failed."
            exit 1
        fi

        # Upgrade system
        echo_msg "Upgrading system..."
        pacman -Sy --needed --noconfirm archlinux-keyring && pacman -Su --noconfirm


    fi
}

# Adjust directory permissions if needed
adjust_dir_permissions() {
    if [ "$DIR_PERMS_CHECKED" = false ]; then
        echo_msg "Adjusting directory permissions..."
        if [ "$(stat -c %a /srv/ftp)" != "555" ]; then
            chmod 555 /srv/ftp
        fi
        if [ "$(stat -c %a /usr/share/polkit-1/rules.d/)" != "755" ]; then
            chmod 755 /usr/share/polkit-1/rules.d/
        fi
        export DIR_PERMS_CHECKED=true
        echo_msg "OK. Directory permissions adjusted."
    fi
}

# Check and install packages
check_and_install_packages() {
    echo_msg "Checking and updating packages (${*})..."

    adjust_dir_permissions
    init_pacman_keyring

    echo_msg "Installing and updating packages ($*)..."
    if ! pacman -Syu --needed --noconfirm "$@"; then
        echo "Failed to install or update packages. If you're getting an error about a missing secret key, you might need to manually import the key. Refer to the Arch Linux wiki for more information: https://wiki.archlinux.org/title/Pacman/Package_signing#Adding_unofficial_keys"
        exit 1
    fi

    echo_msg "OK. All packages (${*}) installed or updated."
}