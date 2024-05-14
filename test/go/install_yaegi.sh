#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "version" go version
check "yaegi is installed at correct path" bash -c "which yaegi | grep /go/bin/yaegi"

# Report result
reportResults
