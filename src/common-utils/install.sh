#!/bin/sh
#-----------------------------------------------------------------------------------------------------------------
# Copyright (c) Bart Venter.
# Licensed under the MIT License. See https://github.com/bartventer/devcontainer-features for license information.
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/devcontainer-features/tree/main/src/common-utils/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>

set -e

# shellcheck disable=SC2034
INSTALL_ZSH="${INSTALLZSH:-"true"}"
# shellcheck disable=SC2034
ADDITIONAL_PACKAGES="${ADDITIONALPACKAGES:-""}"
# shellcheck disable=SC2034
CONFIGURE_ZSH_AS_DEFAULT_SHELL="${CONFIGUREZSHASDEFAULTSHELL:-"false"}"
# shellcheck disable=SC2034
INSTALL_OH_MY_ZSH="${INSTALLOHMYZSH:-"true"}"
# shellcheck disable=SC2034
INSTALL_OH_MY_ZSH_CONFIG="${INSTALLOHMYZSHCONFIG:-"true"}"
# shellcheck disable=SC2034
UPGRADE_PACKAGES="${UPGRADEPACKAGES:-"true"}"
USERNAME="${USERNAME:-"automatic"}"
# shellcheck disable=SC3028
# shellcheck disable=SC2034
USER_UID="${UID:-"automatic"}"
# shellcheck disable=SC2034
USER_GID="${GID:-"automatic"}"

# shellcheck disable=SC2034
MARKER_FILE="/usr/local/etc/vscode-dev-containers/common"


# ***********************
# ** Utility functions **
# ***********************

UTIL_SCRIPT="/usr/local/bin/archlinux_util.sh"

# Check if the utility script exists
if [ ! -f "$UTIL_SCRIPT" ]; then
    echo "Cloning archlinux_util.sh from GitHub to $UTIL_SCRIPT"
    curl -o "$UTIL_SCRIPT" https://raw.githubusercontent.com/bartventer/devcontainer-features/main/scripts/archlinux_util.sh
    chmod +x "$UTIL_SCRIPT"
fi

# Source the utility script
# shellcheck disable=SC1090
. "$UTIL_SCRIPT"

# shellcheck disable=SC1091
. /etc/os-release

# Run checks
check_root
check_system
check_pacman

# Install bash
check_and_install_packages "bash"

# Execute main script
exec /bin/bash "$(dirname "$0")/main.sh" "$@"
exit $?