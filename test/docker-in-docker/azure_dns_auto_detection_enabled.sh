#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "docker-daemon-check" bash -c "./_docker_daemon_check.sh"
# Check if 'internal.cloudapp.net' is present in /etc/resolv.conf
if grep -q 'internal.cloudapp.net' /etc/resolv.conf; then
    # If 'internal.cloudapp.net' is present, check for the --dns flag in the dockerd command
    check "dns flag should be present" ps -ax | grep -v grep | grep -E "dockerd.+--dns"
fi

# Report result
reportResults