#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Negative check function
negative_check() {
    local name="$1"
    shift
    if "$@"; then
        echo "❌ $name check failed."
        exit 1
    else
        echo "✅  Passed '$name'!"
    fi
}
negative_check "terragrunt not installed" command -v terragrunt

# Report result
reportResults
