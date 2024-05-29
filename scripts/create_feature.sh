#!/usr/bin/env bash
#-----------------------------------------------------------------------------------------------------------------
# Copyright © 2024 Bart Venter <bartventer@outlook.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-----------------------------------------------------------------------------------------------------------------
#
# Maintainer: Bart Venter <https://github.com/bartventer>
#
# Description:
# This script creates a new feature in the arch-devcontainer-features repository.
#-----------------------------------------------------------------------------------------------------------------

set -euo pipefail

# Define some colors for output
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[1;33m'
_NC='\033[0m' # No Color

# Function to print colored text
print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${_NC}"
}

# Get the root directory of the git repository
_REPO_ROOT=$(git rev-parse --show-toplevel)

# Default source directory
_DEFAULT_SRCDIR="$_REPO_ROOT/src"
_DEFAULT_TESTDIR="$_REPO_ROOT/test"

# Ask for the source directory
print_color "$_YELLOW" "Enter the path to the source directory where the new feature will be created (default: $_DEFAULT_SRCDIR):"
read -r -e -i "$_DEFAULT_SRCDIR" _SRCDIR

# Ask for the test directory
print_color "$_YELLOW" "Enter the path to the test directory where the new feature tests will be created (default: $_DEFAULT_TESTDIR):"
read -r -e -i "$_DEFAULT_TESTDIR" _TESTDIR

# Ask for the feature ID
print_color "$_YELLOW" "Enter the unique ID of the new feature:"
read -r _FEAT_ID

# Ask for the feature name
_FEAT_NAME=$(echo "$_FEAT_ID" | tr '-' ' ')
print_color "$_YELLOW" "Enter the name of the new feature (default: $_FEAT_NAME):"
read -r -e -i "$_FEAT_NAME" _FEAT_NAME

# Ask for the feature description
print_color "$_YELLOW" "Enter the description of the new feature:"
read -r _FEAT_DESC

# Define an associative array for the default options snippets
declare -A _DEFAULT_OPTS_SNIPPETS
_DEFAULT_OPTS_SNIPPETS=(
    ["version"]="\"version\": {
        \"type\": \"string\",
        \"proposals\": [
            \"latest\"
        ],
        \"default\": \"latest\",
        \"description\": \"$_FEAT_ID version to install\"
    }"
    # Add more options here
)

# Display the available options to the user
_DEFAULT_OPTS="${!_DEFAULT_OPTS_SNIPPETS[*]}"
print_color "$_YELLOW" "Enter the list of default options snippets to include (comma-separated, defaults to '$_DEFAULT_OPTS'):"
print_color "$_YELLOW" "Available options: $_DEFAULT_OPTS"
read -r -e -i "$_DEFAULT_OPTS" _DEFAULT_OPTS

# Convert comma-separated string to array
IFS=',' read -r -a _DEFAULT_OPTS_ARR <<<"$_DEFAULT_OPTS"

# Prepare the options JSON
_OPTIONS_JSON=""
for OPT in "${_DEFAULT_OPTS_ARR[@]}"; do
    _OPTIONS_JSON+="${_DEFAULT_OPTS_SNIPPETS[$OPT]},"
done

# Ask for the keywords
_KEYWORDS="arch linux,$_FEAT_ID"
print_color "$_YELLOW" "Enter the list of keywords (comma-separated, defaults to '$_KEYWORDS'):"
read -r -e -i "$_KEYWORDS" _KEYWORDS

# Convert comma-separated string to array
IFS=',' read -r -a _KEYWORDS_ARR <<<"$_KEYWORDS"

_LICENSE_PATH=$(git rev-parse --show-toplevel)/LICENSE
if [ ! -f "$_LICENSE_PATH" ]; then
    print_color "$_RED" "Error: Could not find LICENSE file at $_LICENSE_PATH"
    exit 1
fi

# Create a temporary directory
_TEMP_DIR=$(mktemp -d -p . -t "$_FEAT_ID-XXXX")
_TMP_FEAT_DIR="$_TEMP_DIR/src/$_FEAT_ID"
_TMP_FEAT_TEST_DIR="$_TEMP_DIR/test/$_FEAT_ID"

print_color "$_GREEN" "Creating feature at $_TMP_FEAT_DIR"
print_color "$_GREEN" "Creating test files at $_TMP_FEAT_TEST_DIR"

# Create the directories
mkdir -p "$_TMP_FEAT_DIR" "$_TMP_FEAT_TEST_DIR"

# Generate the devcontainer-feature.json file
cat <<EOF >"$_TMP_FEAT_DIR/devcontainer-feature.json"
{
    "id": "$_FEAT_ID",
    "version": "0.1.0",
    "name": "$_FEAT_NAME",
    "documentationURL": "https://github.com/bartventer/arch-devcontainer-features/tree/main/src/$_FEAT_ID",
    "licenseURL": "https://github.com/bartventer/arch-devcontainer-features/blob/main/LICENSE",
    "description": "$_FEAT_DESC",
    "options": {
        $_OPTIONS_JSON
    },
    "customizations": {
        "vscode": {
            "extensions": []
        }
    },
    "installsAfter": [
        "ghcr.io/bartventer/arch-devcontainer-features/common-utils"
    ],
    "keywords": [
        $(printf '"%s",' "${_KEYWORDS_ARR[@]}")
    ]
}
EOF

# Generate the install.sh file
cat <<EOF >"$_TMP_FEAT_DIR/install.sh"
#!/bin/sh
$(sed 's/^/# /' "$_LICENSE_PATH")
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/arch-devcontainer-features/tree/main/src/$_FEAT_ID/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>

set -e

# INSTALL SCRIPT GOES HERE
EOF
# INSTALL SCRIPT GOES HERE" >>"$_TMP_FEAT_DIR/install.sh"

# Generate the NOTES.md file
cat <<EOF >"$_TMP_FEAT_DIR/NOTES.md"
## OS Support

This Feature should work on recent versions of Arch Linux.
EOF

# Test directory
# Generate the test.sh file
cat <<EOF >"$_TMP_FEAT_TEST_DIR/test.sh"
#!/bin/bash

set -e

# Optional: Import test library
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Definition specific tests
# Add your tests here

# Report result
reportResults

EOF

# Generate the empty scenarios.json file
touch "$_TMP_FEAT_TEST_DIR/scenarios.json"

print_color "$_GREEN" "OK. Feature created at $_TMP_FEAT_DIR"
print_color "$_GREEN" "Test files created at $_TMP_FEAT_TEST_DIR"

# Preview the directory structure and files
printf '%.0s-' {1..80}
echo
print_color "$_GREEN" "Preview of the directory structure and files:"
tree "$_TEMP_DIR"
echo
for file in "$_TMP_FEAT_DIR"/* "$_TMP_FEAT_TEST_DIR"/*; do
    printf '%.0s-' {1..80}
    echo
    print_color "$_GREEN" "Preview of $file:"
    cat "$file"
    printf '%.0s-' {1..80}
    echo
done

# Ask for confirmation before moving the files to the final location
print_color "$_YELLOW" "Do you want to move the files to the final location? (y/n)"
read -r _CONFIRM
if [[ $_CONFIRM == "y" || $_CONFIRM == "Y" ]]; then
    mv "$_TMP_FEAT_DIR" "$_SRCDIR/"
    print_color "$_GREEN" "Files moved to $_SRCDIR/$_FEAT_ID"
    mv "$_TMP_FEAT_TEST_DIR" "$_TESTDIR/"
    print_color "$_GREEN" "Test files moved to $_TESTDIR/$_FEAT_ID"
    print_color "$_GREEN" "Done."
    rm -rf "$_TEMP_DIR"
else
    print_color "$_RED" "Aborted. The files remain in $_TEMP_DIR"
fi
