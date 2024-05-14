#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "version" go version
check "gox is installed at correct path" bash -c "which gox | grep /usr/bin/gox"

# Report result
reportResults
