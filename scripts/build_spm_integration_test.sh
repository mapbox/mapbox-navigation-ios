#!/usr/bin/env bash

# Updates SPM integration test to use Package.swift from the current commit, builds and archives the app.
# Input argument – iOS version (default value is 14.4)

set -euo pipefail

IOS_VERSION=${1:-14.4}

cd Tests/SPMTest
sed -i '' -e "s/6cc9728a615ed9b08632a6c2d09f7fca57a5c542/`git rev-parse --verify HEAD`/" SPMTest.xcodeproj/project.pbxproj
xcodebuild -scheme SPMTest -destination "platform=iOS Simulator,OS=$IOS_VERSION,name=iPhone 8 Plus" clean build | xcpretty
xcodebuild -scheme SPMTest -sdk iphoneos$IOS_VERSION -destination generic/platform=iOS clean archive CODE_SIGNING_ALLOWED="NO" | xcpretty