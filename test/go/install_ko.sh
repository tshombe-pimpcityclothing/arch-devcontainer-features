#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "version" go version
check "ko is installed at correct path" bash -c "which ko | grep /usr/bin/ko"

# Report result
reportResults
