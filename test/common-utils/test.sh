#!/bin/bash
# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'common-utils' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "common-utils": {}
#    },
#    "remoteUser": "root"
# }
#
# Thus, the value of all options will fall back to the default value in 
# the Feature's 'devcontainer-feature.json'.
#
# These scripts are run as 'root' by default. Although that can be changed
# with the '--remote-user' flag.
# 
# This test can be run with the following command (from the root of this repo):
#
#    devcontainer features test \ 
#                   --common-utils   \
#                   --remote-user devcontainer \
#                   --skip-scenarios   \
#                   --base-image archlinux:base \
#                   .
set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "jq" jq  --version
check "curl" curl  --version
check "git" git  --version
check "zsh" zsh --version
check "ps" ps --version
check "Oh My Zsh! theme" test -e "$HOME"/.oh-my-zsh/custom/themes/devcontainers.zsh-theme
check "zsh theme symlink" test -e "$HOME"/.oh-my-zsh/custom/themes/codespaces.zsh-theme

# Report result
reportResults