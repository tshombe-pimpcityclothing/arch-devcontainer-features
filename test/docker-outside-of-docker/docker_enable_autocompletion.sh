#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "docker-daemon-check" bash -c "./_docker_daemon_check.sh"

# Check if Docker CLI autocompletion script was added
case "${SHELL}" in
*/zsh)
    check "docker-autocompletion-check" test -f "${HOME}/.zsh/completions/_docker"
    ;;
*/bash)
    check "docker-autocompletion-check" test -f "${HOME}/.bash_completion.d/docker"
    ;;
*/fish)
    check "docker-autocompletion-check" test -f "${HOME}/.config/fish/completions/docker.fish"
    ;;
*)
    echo "Shell ${SHELL} not supported for autocompletion."
    ;;
esac

# Report result
reportResults
