#!/bin/bash

# This script replaces SPM checked out MapboxCommon framework for simulator with a debug version.

if [[ -z $1 ]]; then 
    echo "Usage $0 <path to MapboxCommon git repository>"
    exit 1
fi

set -x
set -e

NATIVE_PATH=$1
DESTINATION="generic/platform=iOS Simulator"
NATIVE_VERSION=$(python3 << END
import json
import sys

packageResolved = json.loads(open("Package.resolved", "r").read())
for pin in packageResolved["object"]["pins"]:
    if pin["package"] == "MapboxCommon":
        sys.stdout.write(pin["state"]["version"])
        exit(0)

print("Haven't found Package", file=sys.stderr)
exit(1)
END 
)

NATIVE_SIM_FRAMEWORK_PATH="$(xcodebuild -project MapboxNavigation-SPM.xcodeproj/ -showBuildSettings | grep -m 1 "BUILD_DIR" | grep -oEi "\/.*")/../../SourcePackages/artifacts/MapboxCommon/MapboxCommon.xcframework/ios-arm64_i386_x86_64-simulator"

echo "NATIVE_PATH=$NATIVE_PATH"
echo "DESTINATION=$DESTINATION"
echo "NATIVE_SIM_FRAMEWORK_PATH=$NATIVE_SIM_FRAMEWORK_PATH"

pushd $NATIVE_PATH
git fetch --tags
git switch --detach v$NATIVE_VERSION
rm -rf build
mkdir build
pushd build
# Create NavNative Xcode project
cmake -G Xcode .. \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DBUILD_TYPE=SHARED \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -DMASON_PLATFORM=ios \
    -H../ \
    -DCMAKE_XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION="1" \
    -DCMAKE_XCODE_ATTRIBUTE_CURRENT_SHORT_VERSION="1.0.0" \
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="./lib" \
    -DMAPBOX_COMMON_BUILD_TYPE=SHARED \
    -DCMAKE_OSX_SYSROOT=iphonesimulator

# Build NavNative framework in Debug configuration
xcodebuild \
    CURRENT_PROJECT_VERSION="1" \
    CURRENT_SHORT_VERSION="$NATIVE_VERSION" \
    ONLY_ACTIVE_ARCH=NO \
    SKIP_INSTALL=NO \
    -project MAPBOX_COMMON.xcodeproj \
    -scheme MapboxCommon \
    -configuration Debug \
    -destination "$DESTINATION" \
    build
popd
popd

# Move old framework aside
if [ -d "$NATIVE_SIM_FRAMEWORK_PATH/MapboxCommon.framework" ]; then
    mv "$NATIVE_SIM_FRAMEWORK_PATH/MapboxCommon.framework" "$NATIVE_SIM_FRAMEWORK_PATH/MapboxCommon.framework.backup"
fi

# Replace old framework with debug version
cp -R "$NATIVE_PATH/build/lib/Debug/MapboxCommon.framework" "$NATIVE_SIM_FRAMEWORK_PATH/"
