#!/bin/bash
set -e

# Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "sam version" sam --version | grep -q "1.113.0"

# Report result
reportResults
