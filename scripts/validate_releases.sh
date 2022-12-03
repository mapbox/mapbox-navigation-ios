#!/usr/bin/env bash

set -e

# Used for local testing to make sure that correct Xcode version is used.
# sudo xcode-select --switch /Applications/Xcode_13.2.1.app/Contents/Developer/
# XCODEBUILD=/Applications/Xcode_13.2.1.app/Contents/Developer/usr/bin/xcodebuild
XCODEBUILD=xcodebuild

CURRENT_DIRECTORY=$(pwd)
CURRENT_XCODEBUILD_DIRECTORY=$(xcode-select -print-path)
echo "Current xcodebuild path: ${CURRENT_XCODEBUILD_DIRECTORY}."

cd Tests/SPMTest/UISPMTest/

# Dictionary that stores Navigation SDK version and expected xcodebuild result after resolving dependencies.
# xcodebuild exits with codes defined by sysexits(3): https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/sysexits.3.html.
# It will exit with:
# - EX_OK on success.
# On failure, it will commonly exit with: 
# - EX_USAGE if any options appear malformed.
# - EX_NOINPUT if any input files cannot be found.
# - EX_IOERR if any files cannot be read or written.
# - EX_SOFTWARE if the commands given to xcodebuild fail.
# It may exit with other codes in less common scenarios.
declare -A EXPECTED_XCODEBUILD_RESULTS
SUCCESS_CODE=0
# xcodebuild exits with EX_IOERR (74) in case if it fails to resolve dependencies.
ERROR_CODE=74
EXPECTED_XCODEBUILD_RESULTS=( \
    [2.4.0]=${ERROR_CODE} \
    [2.4.1]=${ERROR_CODE} \
    [2.4.2]=${SUCCESS_CODE} \
    [2.5.0]=${ERROR_CODE} \
    [2.5.1]=${ERROR_CODE} \
    [2.5.2]=${ERROR_CODE} \
    [2.5.3]=${ERROR_CODE} \
    [2.5.4]=${SUCCESS_CODE} \
    [2.6.0]=${ERROR_CODE} \
    [2.6.1]=${ERROR_CODE} \
    [2.6.2]=${SUCCESS_CODE} \
    [2.7.0]=${ERROR_CODE} \
    [2.7.1]=${ERROR_CODE} \
    [2.7.2]=${ERROR_CODE} \
    [2.7.3]=${SUCCESS_CODE} \
    [2.8.0]=${SUCCESS_CODE} \
    [2.8.1]=${SUCCESS_CODE} \
    [2.9.0]=${SUCCESS_CODE}
)

echo "Expected xcodebuild result for:"
for NAVIGATION_SDK_VERSION in "${!EXPECTED_XCODEBUILD_RESULTS[@]}"
do 
    echo "Navigation SDK v${NAVIGATION_SDK_VERSION} is: ${EXPECTED_XCODEBUILD_RESULTS[$NAVIGATION_SDK_VERSION]}."
done

# Dictionary that stores actual xcodebuild result for specific Navigation SDK version.
declare -A ACTUAL_XCODEBUILD_RESULTS

for NAVIGATION_SDK_VERSION in "${!EXPECTED_XCODEBUILD_RESULTS[@]}"
do
    # Make sure that cache is empty before building and resolving dependencies.
    rm -rf /Users/$(whoami)/Library/Caches/org.swift.swiftpm/repositories
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
    rm -rf ~/Library/Caches/com.apple.dt.Xcode/*

    # Remove originally created file with resolved dependencies.
    # Xcode 13.2.1 and Xcode 13.3 Package.resolved file formats are not compatible.
    rm -rf *.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

    # Replace Navigation SDK version placeholder with the one that should be tested.
    echo "Validating Navigation SDK: ${NAVIGATION_SDK_VERSION}."
    sed -i "" "s#NAVIGATION_SDK_VERSION#${NAVIGATION_SDK_VERSION}#g" project.yml

    # Generate Xcode project for specific Navigation SDK version and attempt to resolve dependencies. For certain Navigation SDK versions
    # dependencies resolving will fail due to Mapbox Common misalignment.
    xcodegen generate
    ${XCODEBUILD} -resolvePackageDependencies && ACTUAL_XCODEBUILD_RESULTS[${NAVIGATION_SDK_VERSION}]=$? || ACTUAL_XCODEBUILD_RESULTS[${NAVIGATION_SDK_VERSION}]=$?

    # Validate whether Mapbox Navigation version in generated Xcode project is correct.
    swift sh ./../../../scripts/validate_xcodeproj.swift UISPMTest.xcodeproj ${NAVIGATION_SDK_VERSION}

    # Reset XcodeGen project configuration to original state.
    git checkout project.yml
done

echo "Resolved dependencies results:"
for NAVIGATION_SDK_VERSION in "${!ACTUAL_XCODEBUILD_RESULTS[@]}"
do 
    if [ ${ACTUAL_XCODEBUILD_RESULTS[$NAVIGATION_SDK_VERSION]} -ne ${EXPECTED_XCODEBUILD_RESULTS[$NAVIGATION_SDK_VERSION]} ]
    then
        echo "Actual (${ACTUAL_XCODEBUILD_RESULTS[$NAVIGATION_SDK_VERSION]}) and expected (${EXPECTED_XCODEBUILD_RESULTS[$NAVIGATION_SDK_VERSION]}) xcodebuild exit codes are not equal for ${NAVIGATION_SDK_VERSION}. Exiting..."

        # Return back to initial directory.
        cd ${CURRENT_DIRECTORY}

        exit 1
    else
        echo "Actual and expected xcodebuild exit codes for Navigation SDK v${NAVIGATION_SDK_VERSION} are equal."
    fi
done

echo "Navigation SDK versions were successfully validated."

# Return back to initial directory.
cd ${CURRENT_DIRECTORY}
