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
# Maintainer: Bart Venter <https://github.com/bartventer>
#-----------------------------------------------------------------------------------------------------------------
# This script creates a new feature with the provided source directory and feature name.
# The following flags are required:
#
#       -srcdir /path/to/srcdir
#           The path to the source directory where the new feature will be created.
#
#       -feat-name feature_name
#           The name of the new feature.
#
# Usage: ./create_feature.sh -srcdir [srcdir] -feat-name [feat_name]
#
# Example: ./create_feature.sh -srcdir ./src -feat-name my_feature
#-----------------------------------------------------------------------------------------------------------------

set -euo pipefail

# Default values
_SRCDIR=""
_FEAT_NAME=""

# Parse flags
while (("$#")); do
    case "$1" in
    -srcdir)
        _SRCDIR="$2"
        shift 2
        ;;
    -feat-name)
        _FEAT_NAME="$2"
        shift 2
        ;;
    *)
        echo "Error: Invalid flag $1"
        exit 1
        ;;
    esac
done

# Check if all required flags were provided
if [[ -z $_SRCDIR || -z $_FEAT_NAME ]]; then
    echo "
Error: Missing required flags.

Usage: ./create_feature.sh -srcdir [srcdir] -feat-name [feat_name]
"
    exit 1
fi

_LICENSE_PATH=$(git rev-parse --show-toplevel)/LICENSE
if [ ! -f "$_LICENSE_PATH" ]; then
    echo "Error: Could not find LICENSE file at $_LICENSE_PATH"
    exit 1
fi

_FEAT_DIR="$_SRCDIR/$_FEAT_NAME"

echo "Creating feature $_FEAT_NAME at $_FEAT_DIR"

# Create a new directory at the provided path with the feature name
mkdir -p "$_FEAT_DIR"

# Generate the devcontainer-feature.json file
cat <<EOF >"$_FEAT_DIR/devcontainer-feature.json"
{
    "id": "$_FEAT_NAME",
    "version": "0.1.0",
    "name": "$_FEAT_NAME",
    "documentationURL": "https://github.com/bartventer/arch-devcontainer-features/tree/main/src/$_FEAT_NAME",
    "licenseURL": "https://github.com/bartventer/arch-devcontainer-features/blob/main/LICENSE",
    "description": "Description of the feature goes here.",
    "options": {
        "enableShellCompletion": {
            "type": "boolean",
            "default": true,
            "description": "Enable shell completion for the ${_FEAT_NAME} CLI."
        }
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
        "arch linux",
        "${_FEAT_NAME}"
    ]
}
EOF

# Generate the install.sh file
cat <<EOF >"$_FEAT_DIR/install.sh"
#!/bin/sh
$(sed 's/^/# /' "$_LICENSE_PATH")
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/arch-devcontainer-features/tree/main/src/$_FEAT_NAME/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>

set -e

# INSTALL SCRIPT GOES HERE
EOF
# INSTALL SCRIPT GOES HERE" >>"$_FEAT_DIR/install.sh"

# Generate the NOTES.md file

# Generate the NOTES.md file
cat <<EOF >"$_FEAT_DIR/NOTES.md"
## OS Support

This Feature should work on recent versions of Arch Linux.
EOF

echo "OK. Feature created at $_FEAT_DIR"
