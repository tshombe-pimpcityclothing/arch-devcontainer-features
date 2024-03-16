#!/usr/bin/env bash
#-----------------------------------------------------------------------------------------------------------------
# Copyright (c) Bart Venter.
# Licensed under the MIT License. See https://github.com/bartventer/devcontainer-features for license information.
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/devcontainer-features/tree/main/src/git/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>

GIT_VERSION=${VERSION} # 'system' checks the base image first, else installs 'latest'

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
# shellcheck disable=SC1091
. /etc/os-release

if [ "${ID}" != "arch" ]; then
    echo "Linux distro ${ID} not supported."
    exit 1
fi

if type pacman > /dev/null 2>&1; then
    INSTALL_CMD=pacman
else
    echo "(Error) Unable to find a supported package manager."
    exit 1
fi

# Clean up
clean_up() {
    rm -rf /var/cache/pacman/pkg/*
}
clean_up

pkg_mgr_update() {
    echo "Running ${INSTALL_CMD} -Syu ..."
    ${INSTALL_CMD} -Syu
}

# Checks if packages are installed and installs them if not
check_packages() {
    for pkg in "$@"; do
        if ! pacman -Q "$pkg" > /dev/null 2>&1; then
            pkg_mgr_update
            ${INSTALL_CMD} -S --noconfirm "$pkg"
        fi
    done
}

# If the os provided version is "good enough", just install that.
if [ "${GIT_VERSION}" = "os-provided" ] || [ "${GIT_VERSION}" = "system" ]; then
    if type git > /dev/null 2>&1; then
        echo "Detected existing system install: $(git version)"
        # Clean up
        clean_up
        exit 0
    fi

    echo "Installing git from OS repository"
    check_packages git
    # Clean up
    clean_up
    exit 0
fi

# Install required packages to build if missing
check_packages base-devel curl ca-certificates tar gettext openssl zlib expat pcre2

# Partial version matching
if [ "$(echo "${GIT_VERSION}" | grep -o '\.' | wc -l)" != "2" ]; then
    requested_version="${GIT_VERSION}"
    version_list="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/git/git/tags" | grep -oP '"name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+"' | tr -d '"' | sort -rV )"
    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "current" ]; then
        GIT_VERSION="$(echo "${version_list}" | head -n 1)"
    else
        set +e
        GIT_VERSION="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
        set -e
    fi
    if [ -z "${GIT_VERSION}" ] || ! echo "${version_list}" | grep "^${GIT_VERSION//./\\.}$" > /dev/null 2>&1; then
        echo "Invalid git version: ${requested_version}" >&2
        exit 1
    fi
fi

echo "Downloading source for ${GIT_VERSION}..."
curl -sL https://github.com/git/git/archive/v"${GIT_VERSION}".tar.gz | tar -xzC /tmp 2>&1
echo "Building..."
cd /tmp/git-"${GIT_VERSION}"
make -s USE_LIBPCRE=YesPlease prefix=/usr/local sysconfdir=/etc all && make -s USE_LIBPCRE=YesPlease prefix=/usr/local sysconfdir=/etc install 2>&1
rm -rf /tmp/git-"${GIT_VERSION}"
clean_up
echo "Done!"