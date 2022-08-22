#!/usr/bin/env bash

set -e
set -x

CURRENT_DIRECTORY=$(pwd)
CURRENT_XCODEBUILD=$(xcode-select -print-path)
echo "Current xcodebuild path: ${CURRENT_XCODEBUILD}."

cd Tests/SPMTest/UISPMTest/
NAVIGATION_SDK_VERSION=2.4.0
sed -i "" "s#NAVIGATION_SDK_VERSION#${NAVIGATION_SDK_VERSION}#g" project.yml
xcodegen generate
xcodebuild -resolvePackageDependencies || echo "Failed to resolve dependencies with error: $?."

git checkout project.yml

cd ${CURRENT_DIRECTORY}