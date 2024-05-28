#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
check "gcloud version" gcloud --version
check "gsutil version" gsutil --version
check "gsutil version" bq version

# Report result
reportResults
