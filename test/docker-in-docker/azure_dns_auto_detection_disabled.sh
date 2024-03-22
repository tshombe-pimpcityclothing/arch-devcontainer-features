#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "docker-daemon-check" bash -c "./_docker_daemon_check.sh"
check "dns flag should not be present" test ! "$(pgrep -f 'dockerd.+--dns')"

# Report result
reportResults