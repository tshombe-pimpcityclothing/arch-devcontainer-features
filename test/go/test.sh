#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# go
check "version" go version

# Tools with versions

# gopls
check "gopls version" gopls version
check "gopls is installed at correct path" bash -c "which gopls | grep /go/bin/gopls"

# golangci-lint
check "golangci-lint version" golangci-lint --version
check "golangci-lint is installed at correct path" bash -c "which golangci-lint | grep /go/bin/golangci-lint"

# staticcheck
check "staticcheck version" staticcheck --version
check "staticcheck is installed at correct path" bash -c "which staticcheck | grep /go/bin/staticcheck"

# revive
check "revive version" revive --version
check "revive is installed at correct path" bash -c "which revive | grep /go/bin/revive"

# Tools without versions
_gotools=(
    "goimports-reviser"
    "golines"
    "gomodifytags"
    "gotests"
    "impl"
    "golint"
    "goplay"
)
for tool in "${_gotools[@]}"; do
    check "$tool is installed at correct path" bash -c "which $tool | grep /go/bin/$tool"
done

# Report result
reportResults
