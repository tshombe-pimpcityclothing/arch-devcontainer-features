#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# go
check "version" go version

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

# goimports-reviser
check "goimports-reviser is installed at correct path" bash -c "which goimports-reviser | grep /go/bin/goimports-reviser"

# golines
check "golines is installed at correct path" bash -c "which golines | grep /go/bin/golines"

# gomodifytags
check "gomodifytags is installed at correct path" bash -c "which gomodifytags | grep /go/bin/gomodifytags"

# gotests
check "gotests is installed at correct path" bash -c "which gotests | grep /go/bin/gotests"

# impl
check "impl is installed at correct path" bash -c "which impl | grep /go/bin/impl"

# golint
check "golint is installed at correct path" bash -c "which golint | grep /go/bin/golint"

# goplay
check "goplay is installed at correct path" bash -c "which goplay | grep /go/bin/goplay"

# air
check "air is installed at correct path" bash -c "which air | grep /go/bin/air"

# cobra-cli
check "cobra-cli is installed at correct path" bash -c "which cobra-cli | grep /go/bin/cobra-cli"

# Report result
reportResults
