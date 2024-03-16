#!/bin/bash
set -e

# Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "version" aws --version

# Report result
reportResults