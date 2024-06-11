#!/bin/sh
#-----------------------------------------------------------------------------------------------------------------
# Copyright © 2024 Bart Venter <bartventer@outlook.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-----------------------------------------------------------------------------------------------------------------
#
# Maintainer: Bart Venter <https://github.com/bartventer>
#
# Description:
# This script performs common checks and operations for Arch-based systems. It includes functions for checking
# system requirements, adjusting directory permissions, managing packages, and more. It is intended to be used
# as a utility helper for setting up and managing Arch Linux systems in devcontainer features.

#-----------------------------------------------------------------------------------------------------------------

# Exit on error
set -e

_ARCH_STATE_FILE="/tmp/archlinux_util_state.json"

# Echo message
_CYAN='\033[1;36m'
_BLUE='\033[1;34m'
_NC='\033[0m' # No color

# echo_msg Outputs a message with a timestamp and script path.
# Usage: echo_msg "Message"
echo_msg() {
    message=$1
    script_path=$(realpath "$0")
    printf "[%b%s%b] %s\n" "$_CYAN" "$script_path" "$_NC" "$message"
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

# _adjust_dir_permissions Adjusts directory permissions to secure the system.
# This function is idempotent
# Usage: _adjust_dir_permissions
_adjust_dir_permissions() {
    echo_msg "Adjusting directory permissions..."
    if [ "$(stat -c %a /srv/ftp)" != "555" ]; then
        chmod 555 /srv/ftp
    fi
    if [ "$(stat -c %a /usr/share/polkit-1/rules.d/)" != "755" ]; then
        chmod 755 /usr/share/polkit-1/rules.d/
    fi
    echo_ok "Directory permissions adjusted."
}

# _refresh_and_sort_mirrors Refreshes the package lists and sorts the mirrors by speed.
# Usage: _refresh_and_sort_mirrors
_refresh_and_sort_mirrors() {
    echo_msg "Refreshing package lists and sorting mirrors by speed..."

    # Install reflector if it's not installed
    if ! command -v reflector >/dev/null 2>&1; then
        pacman -Sy --noconfirm --disable-download-timeout reflector
    fi

    # Install rsync if it's not installed
    if ! command -v rsync >/dev/null 2>&1; then
        pacman -Sy --noconfirm --disable-download-timeout rsync
    fi

    # Use reflector to sort the mirrors by speed and update the mirrorlist file
    reflector --verbose --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    # Refresh the package lists
    pacman -Sy --disable-download-timeout
    echo_ok "Package lists refreshed and mirrors sorted by speed."
}

# _init_pacman_keyring Initializes the pacman keyring and upgrades the system.
# This function is idempotent
# Usage: _init_pacman_keyring
_init_pacman_keyring() {
    echo_msg "Initializing pacman keyring..."
    if pacman-key --init && pacman-key --populate archlinux; then
        echo_ok "Pacman keyring initialized."
    else
        echo_msg "ERROR. Pacman keyring initialization failed."
        exit 1
    fi

    # Upgrade system
    echo_msg "Upgrading system..."
    pacman -Sy --needed --noconfirm --disable-download-timeout archlinux-keyring &&
        pacman -Su --noconfirm --disable-download-timeout
    echo_ok "System upgraded."
}

# check_and_install_packages Installs or updates packages using pacman.
# Usage: check_and_install_packages <package1> <package2> ...
# Example: check_and_install_packages coreutils git
check_and_install_packages() {

    _adjust_dir_permissions
    _refresh_and_sort_mirrors
    _init_pacman_keyring

    echo_msg "Installing and updating packages ($*)..."
    if ! pacman -Syu --needed --noconfirm --disable-download-timeout "$@"; then
        echo "Failed to install or update packages."
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

    # Handle zsh
    if [ -f "$HOME/.zshrc" ]; then
        echo "Setting up auto-completion for zsh..."
        if ! grep -q "^[^#]*autoload -U compinit && compinit" "$HOME/.zshrc"; then
            echo "autoload -U compinit && compinit" >>"$HOME/.zshrc"
        fi
        mkdir -p "$HOME/.zsh/completions"
        cp "$autocomplete_script" "$HOME/.zsh/completions/_$command_name"
        echo "Auto-completion ($command_name) installed in $HOME/.zshrc"
    fi

    # Handle bash
    if [ -f "$HOME/.bashrc" ]; then
        echo "Setting up auto-completion for bash..."
        if ! grep -q "^[^#]*source $autocomplete_script" "$HOME/.bashrc"; then
            echo "source $autocomplete_script" >>"$HOME/.bashrc"
        fi
        echo "Auto-completion ($command_name) installed in $HOME/.bashrc"
    fi

    # Handle fish
    if type fish >/dev/null 2>&1; then
        echo "Setting up auto-completion for fish..."
        mkdir -p "$HOME/.config/fish/completions"
        cp "$autocomplete_script" "$HOME/.config/fish/completions/$command_name.fish"
        echo "Auto-completion ($command_name) installed for fish"
    fi
}
