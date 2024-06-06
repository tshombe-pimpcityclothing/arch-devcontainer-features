#!/usr/bin/env bash

set -euo pipefail

echo "🚀 Building devcontainer..."
echo

devcontainer build \
    --log-level debug \
    --workspace-folder .devcontainer/build \
    --image-name ghcr.io/bartventer/arch-devcontainer-features/devcontainer:latest \
    --platform linux/amd64 \
    --push

echo
echo "🎉 OK. Successfully built devcontainer."
