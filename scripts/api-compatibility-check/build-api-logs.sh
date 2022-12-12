#!/usr/bin/env bash

# This script builds MapboxNavigation and MapboxCoreNavigation frameworks and then extracts their public API using swift-api-digester tool.

set -e -o pipefail -u

if [ $# -ne 3 ]; then
    echo "Usage: $0 <root_dir> <core_module_logs_path> <ui_module_logs_path>"
    exit 1
fi

ROOT_DIR=$1
CORE_MODULE_LOGS_PATH=$2
UI_MODULE_LOGS_PATH=$3

PROJECT_PATH=$ROOT_DIR/MapboxNavigation-SPM.xcodeproj/

TARGET=arm64-apple-ios12.0
SDK=iphoneos
CONFIGURATION=Release

xcodebuild -sdk $SDK -destination 'generic/platform=iOS' -project "$PROJECT_PATH" -scheme MapboxNavigation -configuration $CONFIGURATION build
DERIVED_DATA_PATH=$(xcodebuild -destination 'generic/platform=iOS' -sdk $SDK -project "$PROJECT_PATH" -configuration $CONFIGURATION -showBuildSettings | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

xcrun -sdk $SDK swift-api-digester -sdk $(xcrun --sdk $SDK --show-sdk-path) -dump-sdk -module MapboxNavigation -o $UI_MODULE_LOGS_PATH -target $TARGET -I "$DERIVED_DATA_PATH"
xcrun -sdk $SDK swift-api-digester -sdk $(xcrun --sdk $SDK --show-sdk-path) -dump-sdk -module MapboxCoreNavigation -o $CORE_MODULE_LOGS_PATH -target $TARGET -I "$DERIVED_DATA_PATH"
