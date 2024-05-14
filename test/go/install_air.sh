#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "version" go version
check "air is installed at correct path" bash -c "which air | grep /go/bin/air"

# Report result
reportResults
