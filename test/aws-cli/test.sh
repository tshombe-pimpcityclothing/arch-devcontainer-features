#!/bin/bash
# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'aws-cli' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "aws-cli": {}
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
#                   --aws-cli   \
#                   --remote-user root \
#                   --skip-scenarios   \
#                   --base-image archlinux:base \
#
set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "version" aws --version

# Report result
reportResults