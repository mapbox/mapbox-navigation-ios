#!/usr/bin/env bash

# This scripts compares two API logs and posts a comment to the PR with the result of the comparison.

set -e -o pipefail -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ $# -ne 4 ]; then
    echo "Usage: $0 <module_name> <base_api_path> <new_api_path> <breakage_allowlist_path"
    exit 1
fi

MODULE_NAME=$1
BASE_API_PATH=$2
NEW_API_PATH=$3
BREAKAGE_ALLOWLIST_PATH=$4

echo "Building API compatibility report..."
REPORT=$(xcrun --sdk iphoneos swift-api-digester -diagnose-sdk -input-paths "$BASE_API_PATH" -input-paths "$NEW_API_PATH" -breakage-allowlist-path $BREAKAGE_ALLOWLIST_PATH 2>&1 >/dev/null)
echo "Report is $REPORT"

echo "Parsing report..."
pushd "$SCRIPT_DIR/swift-api-compatibility" > /dev/null
COMMENT=$(swift run -c release swift-api-compatibility parse-report "$MODULE_NAME" "$REPORT")
popd

echo "Comment is $COMMENT"

if [[ ! $COMMENT == *"🟢"* ]]; then
    gh pr comment --body "$COMMENT"
    exit 1
else
    echo "No Breaking Changes"
fi
