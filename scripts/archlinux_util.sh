#!/bin/sh
#-----------------------------------------------------------------------------------------------------------------
# Copyright (c) Bart Venter.
# Licensed under the MIT License. See https://github.com/bartventer/arch-devcontainer-features for license information.
#-----------------------------------------------------------------------------------------------------------------
#
# Maintainer: Bart Venter <https://github.com/bartventer>
#
# Description:
# This script performs common checks and operations for Arch-based systems. It includes functions for checking
# system requirements, adjusting directory permissions, managing packages, and more. It is intended to be used
# as a utility helper for setting up and managing Arch Linux systems in devcontainer features.
#
# Environment Variables:
#   _ARCH_VERBOSE_LOGGING: If set to "true", the script will output verbose log messages.
#   _ARCH_DIR_PERMS_CHECKED: If set to "true", the script will skip the directory permissions checks.
#   _ARCH_KEYRING_CHECKED: If set to "true", the script will skip the pacman keyring initialization.
#   _ARCH_MIRRORLIST_UPDATED: If set to "true", the script will skip the mirrorlist update.
#-----------------------------------------------------------------------------------------------------------------

# Exit on error
set -e

_ARCH_DIR_PERMS_CHECKED="${_ARCH_DIR_PERMS_CHECKED:-false}"
_ARCH_KEYRING_CHECKED="${_ARCH_KEYRING_CHECKED:-false}"
_ARCH_VERBOSE_LOGGING="${_ARCH_VERBOSE_LOGGING:-false}"
_ARCH_MIRRORLIST_UPDATED="${_ARCH_MIRRORLIST_UPDATED:-false}"

# Echo message
_CYAN='\033[1;36m'
_BLUE='\033[1;34m'
_NC='\033[0m' # No color

# echo_msg Outputs a message with a timestamp and script path.
# Usage: echo_msg "Message"
echo_msg() {
    message=$1
    script_path=$(realpath "$0")

    if [ "$_ARCH_VERBOSE_LOGGING" = "true" ]; then
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        printf "[%b%s%b] [%b%s%b] %s\n" "$_CYAN" "$script_path" "$_NC" "$_BLUE" "$timestamp" "$_NC" "$message"
    else
        printf "[%b%s%b] %s\n" "$_CYAN" "$script_path" "$_NC" "$message"
    fi
}

# echo_ok Outputs a success message.
# Usage: echo_ok "Message"
echo_ok() {
    echo "✔ OK. $1"
}

# check_root Checks if script is run as root. Exits with an error if it's not.
# Usage: check_root
check_root() {
    echo_msg "Checking if script is run as root..."
    if [ "$(id -u)" -ne 0 ]; then
        printf 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.\n'
        exit 1
    fi
    echo_ok "Script is run as root."
}

# check_system Checks if the system is an Arch-based system. Exits with an error if it's not.
# Usage: check_system
check_system() {
    echo_msg "Checking Arch-based system..."
    if ! grep -q 'ID=arch' /etc/os-release; then
        echo "This script is intended for Arch-based systems. Please run this script on an Arch-based system."
        exit 1
    fi
    echo_ok "On an Arch-based system."
}

# check_pacman Checks if pacman is installed. Exits with an error if it's not installed.
# Usage: check_pacman
check_pacman() {
    echo_msg "Checking if pacman is installed..."
    if ! command -v pacman >/dev/null 2>&1; then
        echo "Pacman could not be found. Please install pacman and try again."
        exit 1
    fi
    echo_ok "Pacman is installed."
}

# adjust_dir_permissions Adjusts directory permissions to secure the system.
# This function is idempotent
# Usage: adjust_dir_permissions
adjust_dir_permissions() {
    if [ "$_ARCH_DIR_PERMS_CHECKED" = false ]; then
        echo_msg "Adjusting directory permissions..."
        if [ "$(stat -c %a /srv/ftp)" != "555" ]; then
            chmod 555 /srv/ftp
        fi
        if [ "$(stat -c %a /usr/share/polkit-1/rules.d/)" != "755" ]; then
            chmod 755 /usr/share/polkit-1/rules.d/
        fi
        export _ARCH_DIR_PERMS_CHECKED=true
        echo_ok "Directory permissions adjusted."
    fi
}

# refresh_and_sort_mirrors Refreshes the package lists and sorts the mirrors by speed.
# Usage: refresh_and_sort_mirrors
refresh_and_sort_mirrors() {
    if [ "$_ARCH_MIRRORLIST_UPDATED" = true ]; then
        return
    fi
    echo_msg "Refreshing package lists and sorting mirrors by speed..."

    # Install reflector if it's not installed
    if ! command -v reflector >/dev/null 2>&1; then
        pacman -Sy --noconfirm reflector
    fi

    # Install rsync if it's not installed
    if ! command -v rsync >/dev/null 2>&1; then
        pacman -Sy --noconfirm rsync
    fi

    # Use reflector to sort the mirrors by speed and update the mirrorlist file
    reflector --verbose --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    # Refresh the package lists
    pacman -Sy
    echo_ok "Package lists refreshed and mirrors sorted by speed."
    export _ARCH_MIRRORLIST_UPDATED=true
}

# init_pacman_keyring Initializes the pacman keyring and upgrades the system.
# This function is idempotent
# Usage: init_pacman_keyring
init_pacman_keyring() {
    if [ "$_ARCH_KEYRING_CHECKED" = false ]; then
        echo_msg "Initializing pacman keyring..."
        if pacman-key --init && pacman-key --populate archlinux; then
            echo_ok "Pacman keyring initialized."
            export _ARCH_KEYRING_CHECKED=true
        else
            echo_msg "ERROR. Pacman keyring initialization failed."
            exit 1
        fi

        # Upgrade system
        echo_msg "Upgrading system..."
        pacman -Sy --needed --noconfirm archlinux-keyring && pacman -Su --noconfirm
        echo_ok "System upgraded."
    fi
}

# check_and_install_packages Installs or updates packages using pacman.
# Usage: check_and_install_packages <package1> <package2> ...
# Example: check_and_install_packages coreutils git
check_and_install_packages() {

    adjust_dir_permissions
    refresh_and_sort_mirrors
    init_pacman_keyring

    echo_msg "Installing and updating packages ($*)..."
    if ! pacman -Syu --needed --noconfirm --disable-download-timeout "$@"; then
        echo "Failed to install or update packages. If you're getting an error about a missing secret key, you might need to manually import the key. Refer to the Arch Linux wiki for more information: https://wiki.archlinux.org/title/Pacman/Package_signing#Adding_unofficial_keys"
        exit 1
    fi

    echo_ok "All packages (${*}) installed or updated."
}

# enable_autocompletion Enables shell auto-completion for a given autocomplete script and command name.
# Usage: enable_autocompletion <autocomplete_script> <command_name>
# Example: enable_autocompletion "$(which aws_completer)" "aws"
enable_autocompletion() {
    autocomplete_script=$1
    command_name=$2

    echo "Enabling shell auto-completion for $command_name..."

    if [ ! -f "$autocomplete_script" ]; then
        echo "Could not find $command_name auto-completion script."
        echo "Auto-completion may not be available."
        return
    fi

    setup_autocompletion() {
        shell_config_file=$1
        shell_setup_commands=$2

        if [ -f "$shell_config_file" ]; then
            # Check if any of the commands are not present in the shell configuration file
            IFS="
"
            should_append_comments=false
            for command in $(printf "%b" "$shell_setup_commands"); do
                if ! grep -q "^[^#]*$command" "$shell_config_file"; then
                    should_append_comments=true
                    break
                fi
            done

            # Check if the complete command is not present in the shell configuration file
            complete_command="complete -C '$autocomplete_script' $command_name"
            if ! grep -q "^[^#]*$complete_command" "$shell_config_file"; then
                should_append_comments=true
            fi

            # Append the comments if any of the commands are not present
            if $should_append_comments; then
                comments="# Generated by $0\n# $(echo "$command_name" | tr '[:lower:]' '[:upper:]') auto-completion"
                printf "\n%b\n" "$comments" >>"$shell_config_file"
            fi

            # Append the commands that are not present
            for command in $(printf "%b" "$shell_setup_commands"); do
                if ! grep -q "^[^#]*$command" "$shell_config_file"; then
                    echo "$command" >>"$shell_config_file"
                fi
            done

            # Append the complete command if it is not present
            if ! grep -q "^[^#]*$complete_command" "$shell_config_file"; then
                echo "$complete_command" >>"$shell_config_file"
            fi
        fi
        echo_ok "Auto-completion ($command_name) installed in $shell_config_file"
    }

    # Define shell configuration files and setup commands
    setup_autocompletion "$HOME/.zshrc" "autoload -U +X compinit && compinit\nautoload -U +X bashcompinit && bashcompinit"
    setup_autocompletion "$HOME/.bashrc" "source $autocomplete_script"
}
