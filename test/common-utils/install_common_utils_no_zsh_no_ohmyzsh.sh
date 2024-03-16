#!/bin/bash
set -e

# Import test library
# shellcheck disable=SC1091
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

# Definition specific tests
check "jq" jq  --version
check "curl" curl  --version
check "git" git  --version
negative_check "zsh not installed" command -v zsh
check "ps" ps --version
negative_check "Oh My Zsh! theme not installed" test -e "$HOME"/.oh-my-zsh/custom/themes/devcontainers.zsh-theme
negative_check "zsh theme symlink not installed" test -e "$HOME"/.oh-my-zsh/custom/themes/codespaces.zsh-theme

# Report result
reportResults