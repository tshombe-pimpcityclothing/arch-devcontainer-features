#!/usr/bin/env bash
#-----------------------------------------------------------------------------------------------------------------
# Copyright (c) Bart Venter.
# Licensed under the MIT License. See https://github.com/bartventer/arch-devcontainer-features for license information.
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/arch-devcontainer-features/tree/main/src/aws-cli/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>

# Set error handling
set -e

# Set default VERSION if not set
VERSION=${VERSION:-"latest"}

# ***********************
# ** Utility functions **
# ***********************

UTIL_SCRIPT="/usr/local/bin/archlinux_util.sh"

# Check if the utility script exists
if [ ! -f "$UTIL_SCRIPT" ]; then
    echo "Cloning archlinux_util.sh from GitHub to $UTIL_SCRIPT"
    curl -o "$UTIL_SCRIPT" https://raw.githubusercontent.com/bartventer/arch-devcontainer-features/main/scripts/archlinux_util.sh
    chmod +x "$UTIL_SCRIPT"
fi

# Source the utility script
# shellcheck disable=SC1090
. "$UTIL_SCRIPT"

# Validates VERSION variable
pkg=""
validate_version() {
    echo "Validating VERSION..."
    case "${VERSION}" in
    latest | v2) pkg="aws-cli-v2" ;;
    v1) pkg="aws-cli" ;;
    *)
        echo "Invalid version. Please set VERSION to 'latest', 'v1', or 'v2'."
        exit 1
        ;;
    esac
    echo "OK. VERSION (${VERSION}) is valid."
}

# ==========
# == Main ==
# ==========

echo "Installing AWS CLI (${VERSION}) devcontainer feature..."

# Check if script is run as root
check_root

# Run checks
check_system
check_pacman

# Install or update package
validate_version
check_and_install_packages "${pkg}"

echo_msg "Done. AWS CLI (${VERSION}) devcontainer feature installed."
