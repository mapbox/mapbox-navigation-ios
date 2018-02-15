#!/usr/bin/env bash

# Formats the Podfile according to the current PR, branch, and fork.

GIT_REPO_URL="${BITRISEIO_PULL_REQUEST_REPOSITORY_URL:=$GIT_REPOSITORY_URL}"
echo "BRANCH: $BITRISE_GIT_BRANCH"
echo "REPOSITORY: $GIT_REPO_URL"

sed -i '' "s;BRANCH_NAME;$BITRISE_GIT_BRANCH;g" Podfile
sed -i '' "s;GIT_REPO_URL;$GIT_REPO_URL;g" Podfile
