#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

check "version" go version
check "goreleaser is installed at correct path" bash -c "which goreleaser | grep /usr/bin/goreleaser"

# Report result
reportResults
