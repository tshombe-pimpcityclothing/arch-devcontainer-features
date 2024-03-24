#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-daemon-check" bash -c "./_docker_daemon_check.sh"

check "docker-buildx" docker buildx version
check "docker-build" docker build ./

check "not installing compose skips docker-compose install" bash -c "! type docker-compose"

# Report result
reportResults