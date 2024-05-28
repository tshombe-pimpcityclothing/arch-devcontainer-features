#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "version" gcloud --version
check "version" gsutil --version
check "version" bq --version

# Report result
reportResults
