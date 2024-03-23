#!/bin/bash
#-----------------------------------------------------------------------------------------------------------------
# Copyright (c) Bart Venter.
# Licensed under the MIT License. See https://github.com/bartventer/devcontainer-features for license information.
#-----------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/bartventer/devcontainer-features/tree/main/src/git/README.md
# Maintainer: Bart Venter <https://github.com/bartventer>
#
# This script will: 
# 
# Install the necessary tools ( jq ,  gh ,  semver ) 
# Get the commit type 
# Get the equivalent version increment
# Get the latest version 
# Increment the version 
# Update the version file 
# Commit, push changes and create a PR 
# 
# You can run this script manually or set up a GitHub Action to run it automatically. 
# Here is an example of a GitHub Action that runs the script: 
# Path: .github/workflows/bump_version.yml
#-----------------------------------------------------------------------------------------------------------------

set -euo pipefail

BASE_BRANCH=${1:-"main"}
DRY_RUN=${2:-"false"}

# GitHub Actions environment variables
CI=${CI:-"false"}
GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-"."}
# GitHub Actions repository variables
GH_USERNAME="${GH_ACTIONS_USERNAME:-"github-actions[bot]"}"
GH_USER_EMAIL="$GH_USERNAME@users.noreply.github.com"
PR_BODY_BUMP_KEY="${PR_BODY_BUMP_KEY:-"BUMP"}"
PR_BODY_IMAGE_KEY="${PR_BODY_IMAGE_KEY:-"IMAGE NAME"}"

# Script variables
VERSION_FILE_NAME="devcontainer-feature.json"
NPM_DEPS=("semver")
SYS_DEPS=("git" "curl" "jq")
DEFAULT_VERSION="0.0.0"
INITIAL_VERSION="1.0.0"
ISSUE_LABEL="bug"

log_info() {
    echo -e "(\033[1;34m$(date '+%Y-%m-%d %H:%M:%S')\033[0m) [\033[1;34mINFO\033[0m] $1"
}

log_warn() {
    echo -e "(\033[1;33m$(date '+%Y-%m-%d %H:%M:%S')\033[0m) [\033[1;33mWARN\033[0m] 🔔 \033[0;33m$1\033[0m" >&2
}

log_error() {
    echo -e "(\033[1;31m$(date '+%Y-%m-%d %H:%M:%S')\033[0m) [\033[1;31mERROR\033[0m] ❕ \033[0;31m$1\033[0m" >&2
}

log_fatal() {
    echo -e "(\033[1;31m$(date '+%Y-%m-%d %H:%M:%S')\033[0m) [\033[1;31mFATAL\033[0m] ❌ \033[0;31m$1\033[0m" >&2
    exit 1
}

install_tools() {
    local missing_deps=0
    if [ "$CI" != "true" ]; then
        for tool in "${NPM_DEPS[@]}" "${SYS_DEPS[@]}"; do
            if ! command -v $tool &> /dev/null; then
                log_error "Tool not found: $tool"
                missing_deps=1
                case $tool in
                    "gh") log_error "Install GitHub CLI: see https://github.com/cli/cli/blob/trunk/docs/install_linux.md";;
                esac
            fi
        done
        if [ $missing_deps -eq 1 ]; then
            log_fatal "Missing dependencies. Exiting..."
        else
            return 0
        fi
    fi

    log_info "Installing npm dependencies..."
    npm install -g "${NPM_DEPS[@]}" || { echo "Failed to install npm tools"; exit 1; }

    log_info "Installing system dependencies..."
    sudo apt-get install -y "${SYS_DEPS[@]}" || { echo "Failed to install system tools"; exit 1; }
}

get_version_increment() {
    local feature_name=$(basename $feature)
    local last_tag=$(git describe --tags --abbrev=0)
    local previous_tag=$(git describe --tags --abbrev=0 $last_tag^)
    local commit_types=$(git log --pretty=%B $previous_tag..$last_tag -- src/$feature_name | grep -oE '^(feat|fix|BREAKING CHANGE)')
    if echo $commit_types | grep -q 'BREAKING CHANGE'; then
        echo 'major'
    elif echo $commit_types | grep -q 'feat'; then
        echo 'minor'
    elif echo $commit_types | grep -q 'fix'; then
        echo 'patch'
    else
        echo ''
    fi
}

# ref: https://github.community/t/how-to-check-if-a-container-image-exists-on-ghcr/154836/3
get_latest_version() {
    local feature=$1
    local user_image="bartventer/devcontainer-features/$(basename $feature)"
    local token=$(curl -s "https://ghcr.io/token?scope=repository:${user_image}:pull" | awk -F'"' '$0=$4')
    local tags=$(curl -s -H "Authorization: Bearer ${token}" "https://ghcr.io/v2/${user_image}/tags/list" | jq -r '.tags[]' 2>/dev/null)
    if [ -z "$tags" ]; then
        echo $DEFAULT_VERSION
    else
        echo $tags | tr ' ' '\n' | sort -V | tail -n 1
    fi
}

increment_version() {
    local version_increment=$1
    local latest_version=$2
    if [ "$latest_version" = "$DEFAULT_VERSION" ]; then
        echo $INITIAL_VERSION
    else
        semver -i $version_increment $latest_version || { echo "Failed to increment version"; exit 1; }
    fi
}

update_version_file() {
    local new_version=$1
    local feature=$2
    local version_file_path="$feature/$VERSION_FILE_NAME"
    if [ "$CI" = "true" ]; then
        version_file_path=${GITHUB_WORKSPACE}/$version_file_path
    fi
    if [ ! -f $version_file_path ]; then
        log_fatal "Version file not found: $version_file_path"
    fi
    log_info "==> Version file path: $version_file_path"
    if [ "$CI" = "true" ]; then
        jq --arg new_version "$new_version" '.version |= $new_version' $version_file_path > "$version_file_path.tmp" && \
            mv "$version_file_path.tmp" $version_file_path \
            || { log_fatal "Failed to update version file"; }
    else
        log_warn "Dry run enabled. Redirecting output to stdout. \
                    \n::feature: $feature \
                    \n::new_version: $new_version"
        jq --arg new_version "$new_version" '.version |= $new_version' $version_file_path
    fi
}

get_github_workflow_url() {
    echo "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/job/$GITHUB_JOB"
}

commit_push_and_create_pr() {
    local feature=$1
    local latest_version=$2
    local new_version=$3
    local commit_message="chore(release/$(basename $feature)): bump version from $latest_version to $new_version"
    local body="_This is an auto-generated PR to bump the image version._
\n\n$PR_BODY_BUMP_KEY version from $latest_version to $new_version
\n\n$PR_BODY_IMAGE_KEY: $(basename $feature)
\n\n**Bump Information:**
- **Feature:** $feature
- **Latest Version:** $latest_version
- **New Version:** $new_version"
    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Dry run enabled. Skipping commit, push and PR creation. Redirecting output to stdout.
                    \n::Commit message: $commit_message
                    \n::PR body: \n$body"
        return
    fi
    workflow_url=$(get_github_workflow_url)
    body="$body\n\n**Workflow Information:**
- **GitHub Actor:** $GITHUB_ACTOR
- **GitHub Repository:** $GITHUB_REPOSITORY
- **GitHub Triggering Actor:** $GITHUB_TRIGGERING_ACTOR
- **GitHub Run ID:** $GITHUB_RUN_ID
- **GitHub Workflow:** $GITHUB_WORKFLOW
- **GitHub Job:** $GITHUB_JOB
- **GitHub Run ID:** $GITHUB_RUN_ID
- **GitHub Run Number:** $GITHUB_RUN_NUMBER
- **GitHub Run Attempt:** $GITHUB_RUN_ATTEMPT
- **GitHub Event Name:** $GITHUB_EVENT_NAME
- **GitHub Runner OS:** $RUNNER_OS
- **GitHub Workflow URL:** $workflow_url"
    git config --global user.email $GH_USER_EMAIL
    git config --global user.name $GH_USERNAME
    git add "$feature/$VERSION_FILE_NAME" || { log_fatal "Failed to add changes"; }
    git commit -m "$commit_message" || { log_fatal "Failed to commit changes"; }
    git push || { log_fatal "Failed to push changes"; }
    if ! gh pr create \
        --title "$commit_message" \
        --body "$body" \
        --base $BASE_BRANCH \
        --head "$(git rev-parse --abbrev-ref HEAD)"; then
        echo "Failed to create PR. Creating an issue instead."
        issue_title="Failed to create PR: $commit_message"
        existing_issue=$(gh issue list --label "$ISSUE_LABEL" --state open --search "$issue_title")
        if [ -z "$existing_issue" ]; then
            gh issue create \
                --title "$issue_title" \
                --label "$ISSUE_LABEL" \
                --body "An error occurred while trying to create a PR. Please check the logs.\n\nWorkflow URL: $(workflow_url)"
        else
            echo "An issue with the same title already exists. Updating the existing issue instead."
            issue_number=$(echo $existing_issue | cut -d' ' -f1)
            gh issue comment $issue_number \
            --body "The workflow failed again. Please check the logs.\n\nWorkflow URL: $(workflow_url)"
        fi
    fi
}

main() {
    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Running in dry run mode. No changes will be made."
    fi
    log_info "ℹ️ Installing dependencies..."
    install_tools
    log_info "✔ OK. Dependencies installed."

    for feature in src/*; do
        feature_name=$(basename $feature)
        echo
        log_info "ℹ️ Checking if files in $feature_name were changed in the last tag..."
        last_tag=$(git describe --tags --abbrev=0)
        previous_tag=$(git describe --tags --abbrev=0 $last_tag^)
        if ! git diff --name-only $previous_tag $last_tag | grep -q "$feature_name"; then
            log_info "No changes for $feature_name in the last tag. Skipping version bump."
            continue
        fi
        log_warn "OK. Changes found for $feature in the last tag."

        log_info "ℹ️ Getting version increment..."
        version_increment=$(get_version_increment)
        if [ -z "$version_increment" ]; then
            log_warn "No valid commit type found. Skipping version bump."
            continue
        fi
        log_info "✔ OK. Version increment: $version_increment"

        log_info "ℹ️ Getting latest version..."
        latest_version=$(get_latest_version $feature)
        log_info "✔ OK. Latest version: $latest_version"

        log_info "ℹ️ Incrementing version..."
        new_version=$(increment_version $version_increment $latest_version)
        log_info "✔ OK. New version: $new_version"

        log_info "ℹ️ Updating version file..."
        update_version_file $new_version $feature
        log_info "✔ OK. Version file updated."

        log_info "Committing, pushing changes and creating PR..."
        commit_push_and_create_pr $feature $latest_version $new_version
        log_info "✔ OK. Changes committed, pushed and PR created."
    done
}

log_info "🚀 Starting version bump..."
main
log_info "✅ Done. Version bump completed."