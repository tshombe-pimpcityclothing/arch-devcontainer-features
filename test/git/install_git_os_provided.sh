#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "version" git  --version

# Clone a Git repository to a temporary directory
tmp_dir=$(mktemp -d)
git clone https://github.com/devcontainers/feature-starter.git "$tmp_dir"
cd "$tmp_dir"

# Run the perl test inside the cloned repository
check "perl" bash -c "git -c grep.patternType=perl grep -q 'a.+b'"

# Clean up the temporary directory
rm -rf "$tmp_dir"

# Report result
reportResults