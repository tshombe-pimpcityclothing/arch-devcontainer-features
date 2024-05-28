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
# Docs: https://github.com/bartventer/arch-devcontainer-features/tree/main/src/go/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>

set -e

GOLANGCI_LINT_VERSION=${GOLANGCILINTVERSION:-"latest"}
INSTALL_GO_RELEASER=${INSTALLGORELEASER:-"false"}
INSTALL_GOX=${INSTALLGOX:-"false"}
INSTALL_KO=${INSTALLKO:-"false"}
INSTALL_YAEGI=${INSTALLYAEGI:-"false"}
INSTALL_AIR=${INSTALLAIR:-"false"}
INSTALL_COBRA_CLI=${INSTALLCOBRACLI:-"false"}

# revise_golangci_version Revises the GolangCI-Lint version to install.
# Arguments:
#   $1 - The GolangCI-Lint version to revise.
# Returns:
#   The revised GolangCI-Lint version.
revise_golangci_version() {
    version="$1"
    case "${version}" in
    latest) echo "latest" && return ;;
    [0-9]*) version="v${version}" ;;
    v*) ;;                      # if version starts with 'v', do nothing
    *) version="v${version}" ;; # for all other cases, prepend 'v'
    esac
    url="https://api.github.com/repos/golangci/golangci-lint/releases/tags/$version"
    if ! curl --silent --fail "$url" >/dev/null; then
        echo "
Error: The GolangCI-Lint version '${version}' does not exist.
See https://github.com/golangci/golangci-lint/releases for available versions."
        exit 1
    fi
    echo "${version}"
}

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
        sed "s|scripts/archlinux_util.sh|$_UTIL_SCRIPT|" "$_UTIL_SCRIPT_SHA256" | sha256sum --check && echo "SHA256 verified." || exit 1
        chmod +x "$_UTIL_SCRIPT"
        rm -f "$_UTIL_SCRIPT_SHA256" "$_UTIL_SCRIPT_SIG"
        unset _UTIL_SCRIPT_SHA256 _UTIL_SCRIPT_SIG
        echo "OK"
    )
fi

# shellcheck disable=SC1091
# shellcheck source=scripts/archlinux_util.sh
. "$_UTIL_SCRIPT"

# Source /etc/os-release to get OS info
# shellcheck disable=SC1091
# shellcheck source=/etc/os-release
. /etc/os-release

# Run checks
check_root
check_system
check_pacman

# Install Go
# go-tools: https://gitlab.archlinux.org/archlinux/packaging/packages/go-tools/-/blob/main/PKGBUILD?ref_type=heads
PACKAGES="go go-tools delve which"
if [ "$INSTALL_GO_RELEASER" = "true" ]; then
    PACKAGES="$PACKAGES goreleaser"
fi
if [ "$INSTALL_GOX" = "true" ]; then
    PACKAGES="$PACKAGES gox"
fi
if [ "$INSTALL_KO" = "true" ]; then
    PACKAGES="$PACKAGES ko"
fi
if [ "$INSTALL_YAEGI" = "true" ]; then
    PACKAGES="$PACKAGES yaegi"
fi
# shellcheck disable=SC2086
check_and_install_packages $PACKAGES

GO_TOOLS="\
    golang.org/x/tools/gopls@latest \
    github.com/golangci/golangci-lint/cmd/golangci-lint@$(revise_golangci_version "$GOLANGCI_LINT_VERSION") \
    honnef.co/go/tools/cmd/staticcheck@latest \
    github.com/mgechev/revive@latest \
    github.com/incu6us/goimports-reviser/v2@latest \
    github.com/segmentio/golines@latest \
    github.com/fatih/gomodifytags@latest \
    github.com/cweill/gotests/gotests@latest \
    github.com/josharian/impl@latest \
    golang.org/x/lint/golint@latest \
    github.com/haya14busa/goplay/cmd/goplay@latest \
    github.com/766b/go-outliner@latest"

# Add Air to the list of Go tools
if [ "$INSTALL_AIR" = "true" ]; then
    GO_TOOLS="${GO_TOOLS} github.com/cosmtrek/air@latest"
fi

# Add Cobra CLI to the list of Go tools
if [ "$INSTALL_COBRA_CLI" = "true" ]; then
    GO_TOOLS="${GO_TOOLS} github.com/spf13/cobra-cli@latest"
fi

echo_msg "Installing Go tools..."
echo "${GO_TOOLS}" | xargs -n 1 go install

echo "Done. Successfully installed Go and Go tools."
