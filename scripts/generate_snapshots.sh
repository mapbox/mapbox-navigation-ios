#!/usr/bin/env bash

# Turns on recording in all .swift-files inside ../MapboxNavigationTests, runs the testing target, and turns recording back to false.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
find "${DIR}/../MapboxNavigationTests" -name "*.swift" -exec sed -i '' "s/recordMode = false/recordMode = true/g" {} \;
xcodebuild -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=12.1,name=iPhone 6 Plus' -project MapboxNavigation.xcodeproj -scheme MapboxNavigation clean build test | xcpretty
xcodebuild -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=12.2,name=iPhone 6 Plus' -project MapboxNavigation.xcodeproj -scheme MapboxNavigation clean build test | xcpretty
xcodebuild -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=13.5,name=iPhone 8 Plus' -project MapboxNavigation.xcodeproj -scheme MapboxNavigation clean build test | xcpretty
find "${DIR}/../MapboxNavigationTests" -name "*.swift" -exec sed -i '' "s/recordMode = true/recordMode = false/g" {} \;
 