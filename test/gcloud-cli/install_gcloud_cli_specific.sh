#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "version" gcloud --version | grep "477.0.0"

# Report result
reportResults
