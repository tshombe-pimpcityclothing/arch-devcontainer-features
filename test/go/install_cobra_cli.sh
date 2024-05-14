#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "version" go version
check "cobra-cli is installed at correct path" bash -c "which cobra-cli | grep /go/bin/cobra-cli"

# Report result
reportResults
