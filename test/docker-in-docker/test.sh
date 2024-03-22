#!/bin/bash
# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'docker-in-docker' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "docker-in-docker": {}
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
#                   --docker-in-docker   \
#                   --remote-user root \
#                   --skip-scenarios   \
#                   --base-image archlinux:base \
#                   .
set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Feature specific tests
check "docker-daemon-check" bash -c "./_docker_daemon_check.sh"
check "version" docker  --version
check "docker-init-exists" bash -c "ls /usr/local/share/docker-init.sh"

check "log-exists" bash -c "ls /tmp/dockerd.log"
check "log-for-completion" bash -c "cat /tmp/dockerd.log | grep 'Daemon has completed initialization'"
check "log-contents" bash -c "cat /tmp/dockerd.log | grep 'API listen on /var/run/docker.sock'"

# Report result
reportResults