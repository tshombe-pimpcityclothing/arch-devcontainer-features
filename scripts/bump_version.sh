#!/bin/bash
#-----------------------------------------------------------------------------------------------------------------
# Copyright (c) Bart Venter.
# Licensed under the MIT License. See https://github.com/bartventer/devcontainer-features for license information.
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/devcontainer-features/tree/main/src/git/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>

set -euo pipefail

GH_USERNAME=${1:-"github-actions[bot]"}
GH_USER_EMAIL="$GH_USERNAME@users.noreply.github.com"
BASE_BRANCH=${2:-"main"}
VERSION_FILE_NAME="devcontainer-feature.json"

install_tools() {
    echo "Installing tools..."
    npm install -g jq gh semver || { echo "Failed to install tools"; exit 1; }
}

get_commit_type() {
    echo "Getting commit type..."
    git log --since="$(git describe --tags --abbrev=0)" --pretty=%B | cut -d ':' -f 1 || { echo "Failed to get commit type"; exit 1; }
}

get_version_increment() {
    local commit_type=$1
    echo "Getting version increment for commit type: $commit_type..."
    case "$commit_type" in
        "feat") echo "minor";;
        "fix") echo "patch";;
        "BREAKING CHANGE") echo "major";;
        *) echo "";;
    esac
}

get_latest_version() {
    local feature=$1
    echo "Getting latest version for feature: $feature..."
    gh cr list ghcr.io/bartventer/devcontainer-features/$(basename $feature) \
        --limit 1 \
        --format json \
        | jq -r '.[0].tag' || echo "1.0.0"
}

increment_version() {
    local version_increment=$1
    local latest_version=$2
    echo "Incrementing version from $latest_version by $version_increment..."
    semver -i $version_increment $latest_version || { echo "Failed to increment version"; exit 1; }
}

update_version_file() {
    local new_version=$1
    local feature=$2
    local version_file_path="$feature/$VERSION_FILE_NAME"
    echo "Updating version file to $new_version for feature: $feature..."
    jq --arg new_version "$new_version" '.version |= $new_version' $version_file_path > "$version_file_path.tmp" && \
        mv "$version_file_path.tmp" $version_file_path \
        || { echo "Failed to update version file"; exit 1; }
}

commit_and_push_changes() {
    local feature=$1
    local latest_version=$2
    local new_version=$3
    local commit_message="chore(release/$(basename $feature)): bump version from $latest_version to $new_version"
    echo "Committing and pushing changes for feature: $feature..."
    git config --global user.email $GH_USER_EMAIL
    git config --global user.name $GH_USERNAME
    git add "$feature/$VERSION_FILE_NAME"
    git commit -m "$commit_message"
    git push || { echo "Failed to push changes"; exit 1; }
    create_pr $feature $latest_version $new_version "$commit_message"
}

create_pr() {
    local feature=$1
    local latest_version=$2
    local new_version=$3
    local commit_message=$4
    echo "Creating PR for feature: $feature..."
    gh pr create --title "$commit_message" \
                 --body "Bump version from $latest_version to $new_version\n\nImage Name: $(basename $feature)" \
                 --base $BASE_BRANCH \
                 --head "$(git rev-parse --abbrev-ref HEAD)" || { echo "Failed to create PR"; exit 1; }
}

main() {
    install_tools

    for feature in src/*; do
        if ! git log --since="$(git describe --tags --abbrev=0)" --name-only --pretty=format: | grep -q "$feature"; then
            echo "No recent commits for $feature. Skipping version bump."
            continue
        fi

        commit_type=$(get_commit_type)
        version_increment=$(get_version_increment $commit_type)

        if [ -z "$version_increment" ]; then
            echo "No valid commit type found. Skipping version bump."
            continue
        fi

        latest_version=$(get_latest_version $feature)
        new_version=$(increment_version $version_increment $latest_version)

        update_version_file $new_version $feature
        commit_and_push_changes $feature $latest_version $new_version
    done
}

main