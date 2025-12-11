#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Usage: $0 <version> <target_environment> <source_path>"
    echo "Example: $0 2.20.3 docs.mapbox.com-staging build/docs/2.20.3"
    exit 1
fi

VERSION=$1
TARGET_ENVIRONMENT=$2
SOURCE_PATH=$3

# Validate version format
if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-.+)?$ ]]; then
    echo "Error: Version '${VERSION}' does not match the required format."
    echo "Format: X.Y.Z or X.Y.Z-suffix (e.g., 2.20.3, 2.21.0-beta.1)"
    exit 1
fi

# Validate target environment
if [[ "${TARGET_ENVIRONMENT}" != "docs.mapbox.com" ]] && [[ "${TARGET_ENVIRONMENT}" != "docs.mapbox.com-staging" ]]; then
    echo "Error: Target environment '${TARGET_ENVIRONMENT}' is invalid."
    echo "Allowed values: docs.mapbox.com, docs.mapbox.com-staging"
    exit 1
fi

# Validate source path
if [[ ! -f "${SOURCE_PATH}/index.html" ]]; then
    echo "Error: Documentation not found at '${SOURCE_PATH}'."
    echo "Missing index.html file."
    exit 1
fi

echo "########################################################"
echo "PUBLISHING DOCS FOR VERSION: ${VERSION}"
echo "########################################################"
echo "SOURCE_PATH: ${SOURCE_PATH}"
echo "TARGET_ENVIRONMENT: ${TARGET_ENVIRONMENT}"
echo "########################################################"

s5cmd sync \
    "${SOURCE_PATH}/*" \
    "s3://${TARGET_ENVIRONMENT}/ios/navigation/api/${VERSION}/"

echo "########################################################"
echo "DOCS PUBLISHED SUCCESSFULLY"
echo "URL: https://${TARGET_ENVIRONMENT}/ios/navigation/api/${VERSION}/"
echo "########################################################"

