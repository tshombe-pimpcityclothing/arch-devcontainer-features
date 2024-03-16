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

if [ "$(id -u)" -ne 0 ]; then
    # shellcheck disable=SC3037
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi


# Initialize pacman keyring
pacman-key --init

# Fix directory permissions
chmod 555 /srv/ftp/
chmod 755 /usr/share/polkit-1/rules.d/

# shellcheck disable=SC1091
. /etc/os-release
# Install bash before executing
pacman -Syu --noconfirm bash

exec /bin/bash "$(dirname "$0")/main.sh" "$@"
exit $?