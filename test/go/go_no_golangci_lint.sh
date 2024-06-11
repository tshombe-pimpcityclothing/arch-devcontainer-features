#!/bin/bash

set -e

checkNotInstalled() {
    local message="$1"
    local command="$2"

    if ! command -v "$command" >/dev/null 2>&1; then
        echo "✅ $message"
    else
        echo "❌ $message"
        exit 1
    fi
}

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# go
check "version" go version

# golangci-lint
checkNotInstalled "golangci-lint is not installed" golangci-lint

# Report result
reportResults
