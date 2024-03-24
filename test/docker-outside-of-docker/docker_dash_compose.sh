#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-daemon-check" bash -c "./_docker_daemon_check.sh"

check "docker-compose" bash -c "docker-compose --version"

check "installs compose-switch" bash -c "[[ -f /usr/local/bin/compose-switch ]]"

# Report result
reportResults