#!/bin/bash
set -e

# Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Additional packages
check "whois" whois --version
check "dig" dig -v
check "traceroute" traceroute --version

# Report result
reportResults