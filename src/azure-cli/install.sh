#!/bin/sh
# MIT License
#
# Copyright (c) 2024 Bart Venter <bartventer@outlook.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/arch-devcontainer-features/tree/main/src/azure-cli/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>

set -e

# install_azure_cli Installs the Azure CLI
install_azure_cli() {
    check_and_install_packages azure-cli
}

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
        _TARFILE="arch-devcontainer-features-$_TAG_NAME.tar.gz"
        curl -sSL -o "$_TMP_DIR/${_TARFILE}" "$_BASE_URL/$_TARFILE"
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
        tar xzf "$_TMP_DIR/$_TARFILE" -C "$_TMP_DIR"
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

# ==========
# == Main ==
# ==========

echo_msg "Installing Azure CLI devcontainer feature..."

# Check if script is run as root
check_root

# Run checks
check_system
check_pacman

install_azure_cli

echo_msg "Done. Azure CLI devcontainer feature installed successfully."
