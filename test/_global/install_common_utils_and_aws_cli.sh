#!/bin/bash
set -e

# Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Check that the common utilities are installed
check "jq" jq  --version
check "curl" curl  --version
check "git" git  --version
check "zsh" zsh --version
check "ps" ps --version
check "Oh My Zsh! theme" test -e "$HOME"/.oh-my-zsh/custom/themes/devcontainers.zsh-theme
check "zsh theme symlink" test -e "$HOME"/.oh-my-zsh/custom/themes/codespaces.zsh-theme

# Check that AWS CLI is installed and its version is the latest
check "version" aws --version

# Report result
reportResults