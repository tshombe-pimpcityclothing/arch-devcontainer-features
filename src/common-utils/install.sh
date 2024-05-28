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
        echo ":: Downloading utility script..."
        _UTIL_SCRIPT_SHA256="$_UTIL_SCRIPT.sha256"
        _UTIL_SCRIPT_SIG="$_UTIL_SCRIPT.sha256.asc"
        curl -sSL -o "$_UTIL_SCRIPT" "https://raw.githubusercontent.com/bartventer/arch-devcontainer-features/main/scripts/archlinux_util.sh"
        _TAG_NAME=$(curl --silent "https://api.github.com/repos/bartventer/arch-devcontainer-features/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        _BASE_URL="https://github.com/bartventer/arch-devcontainer-features/releases/download/$_TAG_NAME"
        curl -sSL -o "$_UTIL_SCRIPT_SHA256" "$_BASE_URL/archlinux_util.sh.sha256"
        curl -sSL -o "$_UTIL_SCRIPT_SIG" "$_BASE_URL/archlinux_util.sh.sha256.asc"
        unset _TAG_NAME _BASE_URL
        echo "OK"

        # Import GPG key
        echo ":: Importing GPG key..."
        _UTIL_SCRIPT_GPG_KEY=E0AB6303ACAA7621EABF6D42E3730B880D82141A
        gpg --keyserver keyserver.ubuntu.com --recv-keys "$_UTIL_SCRIPT_GPG_KEY"
        unset _UTIL_SCRIPT_GPG_KEY
        echo "OK"

        # Verify SHA256 and signature
        echo "::Verifying SHA256 and signature..."
        gpg --verify "$_UTIL_SCRIPT_SIG" "$_UTIL_SCRIPT_SHA256"
        sed "s|./scripts/archlinux_util.sh|$_UTIL_SCRIPT|" "$_UTIL_SCRIPT_SHA256" | sha256sum --check && echo "SHA256 verified." || exit 1
        chmod +x "$_UTIL_SCRIPT"
        rm -f "$_UTIL_SCRIPT_SHA256" "$_UTIL_SCRIPT_SIG"
        unset _UTIL_SCRIPT_SHA256 _UTIL_SCRIPT_SIG
        echo "OK"
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
