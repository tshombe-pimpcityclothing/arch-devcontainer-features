#!/usr/bin/env bash

# This script generates release assets for a GitHub release.
# Usage: ./generate_assets.sh --dist <dist_dir> --version <version>

set -euo pipefail

_DIST_DIR="dist"
_VERSION=""
_PARAMS=""
_REPOSITORY_NAME="$(basename "${GITHUB_REPOSITORY:-"$(git config --get remote.origin.url)"}" .git)"
[[ -z "${_REPOSITORY_NAME}" ]] && echo "Error: Could not determine repository name" && exit 1
_ROOT="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}"

while (("$#")); do
    case "$1" in
    --*=*) # support for `--flag=value`
        echo "Error: Unsupported flag $1" >&2
        exit 1
        ;;
    --dist)
        _DIST_DIR=$2
        shift 2
        ;;
    --version)
        _VERSION=$2
        shift 2
        ;;
    --) # end argument parsing
        shift
        break
        ;;
    *) # preserve positional arguments
        _PARAMS="$_PARAMS $1"
        shift
        ;;
    esac
done

# Validations
[[ -z "${_DIST_DIR:-}" ]] && echo "Error: --dist flag is required" && exit 1
[[ -z "${_VERSION:-}" ]] && echo "Error: --version flag is required" && exit 1

echo "ℹ️ Generating release assets in $_DIST_DIR"

# Create the dist directory if it doesn't exist
mkdir -p "$_DIST_DIR"

# Create a tarball of the repository
_FILENAME=$(basename "${_REPOSITORY_NAME}-${_VERSION}.tar.gz")
tar -czf "$_DIST_DIR/${_FILENAME}" --exclude="$_DIST_DIR" -C "$_ROOT" .

# Generate checksum for the tarball
(
    cd "$_DIST_DIR" || exit
    sha256sum "${_FILENAME}" >checksums.txt
)

# Sign the checksums file
gpg --detach-sign --armor "$_DIST_DIR/checksums.txt"

echo
echo "ℹ️ Generated the following assets:"
ls -l "$_DIST_DIR"
echo

echo "✔️ OK. All assets generated."
