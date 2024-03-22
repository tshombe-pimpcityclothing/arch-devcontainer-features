#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib


# Definition specific tests
check "docker-daemon-check" bash -c "./_docker_daemon_check.sh"

check "default address pool setting set" ps -ax | grep -v grep | grep -E "dockerd.+base=192.168.0.0/16,size=24"

# Report result
reportResults