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
# Environment Variables:
#   ARCH_VERBOSE_LOGGING: If set to "true", the script will output verbose log messages.
#   ARCH_DIR_PERMS_CHECKED: If set to "true", the script will skip the directory permissions checks.
#   ARCH_KEYRING_CHECKED: If set to "true", the script will skip the pacman keyring initialization.
#
#-----------------------------------------------------------------------------------------------------------------

# Exit on error
set -e

ARCH_DIR_PERMS_CHECKED="${ARCH_DIR_PERMS_CHECKED:-false}"
ARCH_KEYRING_CHECKED="${ARCH_KEYRING_CHECKED:-false}"
ARCH_VERBOSE_LOGGING="${ARCH_VERBOSE_LOGGING:-false}"

# Echo message
CYAN='\033[1;36m'
BLUE='\033[1;34m'
NC='\033[0m' # No color
echo_msg() {
    message=$1
    script_path=$(realpath "$0")

    if [ "$ARCH_VERBOSE_LOGGING" = "true" ]; then
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        printf "[%b%s%b] [%b%s%b] %s\n" "$CYAN" "$script_path" "$NC" "$BLUE" "$timestamp" "$NC" "$message"
    else
        printf "[%b%s%b] %s\n" "$CYAN" "$script_path" "$NC" "$message"
    fi
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
    if [ "$ARCH_KEYRING_CHECKED" = false ]; then
        echo_msg "Initializing pacman keyring..."
        if pacman-key --init && pacman-key --populate archlinux; then
            echo_msg "OK. Pacman keyring initialized."
            export ARCH_KEYRING_CHECKED=true
        else
            echo_msg "ERROR. Pacman keyring initialization failed."
            exit 1
        fi

        # Upgrade system
        echo_msg "Upgrading system..."
        pacman -Sy --needed --noconfirm archlinux-keyring && pacman -Su --noconfirm
        echo_msg "OK. System upgraded."
    fi
}

# Adjust directory permissions if needed
adjust_dir_permissions() {
    if [ "$ARCH_DIR_PERMS_CHECKED" = false ]; then
        echo_msg "Adjusting directory permissions..."
        if [ "$(stat -c %a /srv/ftp)" != "555" ]; then
            chmod 555 /srv/ftp
        fi
        if [ "$(stat -c %a /usr/share/polkit-1/rules.d/)" != "755" ]; then
            chmod 755 /usr/share/polkit-1/rules.d/
        fi
        export ARCH_DIR_PERMS_CHECKED=true
        echo_msg "OK. Directory permissions adjusted."
    fi
}

# Check and install packages
check_and_install_packages() {

    adjust_dir_permissions
    init_pacman_keyring

    echo_msg "Installing and updating packages ($*)..."
    if ! pacman -Syu --needed --noconfirm "$@"; then
        echo "Failed to install or update packages. If you're getting an error about a missing secret key, you might need to manually import the key. Refer to the Arch Linux wiki for more information: https://wiki.archlinux.org/title/Pacman/Package_signing#Adding_unofficial_keys"
        exit 1
    fi

    echo_msg "OK. All packages (${*}) installed or updated."
}