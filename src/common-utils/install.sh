#!/bin/sh
#-----------------------------------------------------------------------------------------------------------------
# Copyright (c) Bart Venter.
# Licensed under the MIT License. See https://github.com/bartventer/arch-devcontainer-features for license information.
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/arch-devcontainer-features/tree/main/src/common-utils/README.md
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

_UTIL_SCRIPT="/usr/local/bin/archlinux_util.sh"
if [ ! -x "$_UTIL_SCRIPT" ]; then
    (
        _TMP_DIR=$(mktemp --directory --suffix=arch-devcontainer)
        echo ":: Downloading release tar..."
        _TAG_NAME=$(curl --silent "https://api.github.com/repos/bartventer/arch-devcontainer-features/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        _BASE_URL="https://github.com/bartventer/arch-devcontainer-features/releases/download/$_TAG_NAME"
        curl -sSL -o "$_TMP_DIR/release.tar.gz" "$_BASE_URL/arch-devcontainer-features-$_TAG_NAME.tar.gz"
        curl -sSL -o "$_TMP_DIR/checksums.txt" "$_BASE_URL/checksums.txt"
        curl -sSL -o "$_TMP_DIR/checksums.txt.asc" "$_BASE_URL/checksums.txt.asc"
        echo "OK"

        echo ":: Importing GPG key..."
        _REPO_GPG_KEY=E0AB6303ACAA7621EABF6D42E3730B880D82141A
        gpg --keyserver keyserver.ubuntu.com --recv-keys "$_REPO_GPG_KEY"
        echo "OK"

        echo ":: Verifying checksums signature..."
        cd "$_TMP_DIR"
        gpg --verify checksums.txt.asc checksums.txt
        echo "OK"

        echo ":: Verifying checksums..."
        sha256sum -c checksums.txt
        echo "OK"

        echo ":: Extracting tar..."
        tar xzf release.tar.gz
        echo "OK"

        echo ":: Moving scripts..."
        mv ./scripts/archlinux_util.sh "$_UTIL_SCRIPT"
        chmod +x "$_UTIL_SCRIPT"
        echo "OK"

        # Clean up
        rm -rf "$_TMP_DIR"
    )
fi

# shellcheck disable=SC1091
# shellcheck source=scripts/archlinux_util.sh
. "$_UTIL_SCRIPT"

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
