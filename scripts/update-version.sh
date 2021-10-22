#!/usr/bin/env bash

set -e
set -o pipefail
set -u

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
function bump_xcode_proj_versions {
    xcrun agvtool bump -all
    xcrun agvtool new-marketing-version "${SHORT_VERSION}"
}
function agvtool_on {
    local PROJ_NAME=$1
    local TMP_DIR=$(uuidgen)
    mkdir $TMP_DIR
    mv *.xcodeproj $TMP_DIR
    mv $TMP_DIR/$PROJ_NAME ./
    bump_xcode_proj_versions
    mv $TMP_DIR/*.xcodeproj ./
    rm -rf $TMP_DIR
}
trap finish EXIT

if [ $# -eq 0 ]; then
    echo "Usage: v<semantic version>"
    exit 1
fi

SEM_VERSION=$1
SEM_VERSION=${SEM_VERSION/#v}
SHORT_VERSION=${SEM_VERSION%-*}
MINOR_VERSION=${SEM_VERSION%.*}
YEAR=$(date '+%Y')

step "Version ${SEM_VERSION}"

step "Updating Xcode targets to version ${SHORT_VERSION}…"

# agvtool doesn't work when there are multiple xcodeproj in the directory. So, we temporarily move xcodeproj files aside to fulfill agvtool requirements. 
agvtool_on MapboxNavigation-SPM.xcodeproj
agvtool_on MapboxNavigation.xcodeproj

step "Updating CocoaPods podspecs to version ${SEM_VERSION}…"

find . -type f -name '*.podspec' -exec sed -i '' "s/^ *s.version *=.*$/  s.version = '${SEM_VERSION}'/" {} +

if [[ $SHORT_VERSION != $SEM_VERSION ]]; then
    step "Updating prerelease CocoaPods podspecs…"
    cp MapboxCoreNavigation.podspec MapboxCoreNavigation-pre.podspec
    cp MapboxNavigation.podspec MapboxNavigation-pre.podspec
    sed -i '' -E "s/(\.name *= *\"[^\"]+)\"/\1-pre\"/g; s/(\.dependency *\"MapboxCoreNavigation)\"/\1-pre\"/g" *-pre.podspec
fi

step "Updating CocoaPods installation test fixture…"

cd Tests/CocoaPodsTest/PodInstall/
pod update
cd -

cd Sources/MapboxCoreNavigation/
cp Info.plist MBXInfo.plist
plutil -replace CFBundleName -string 'MapboxCoreNavigation' MBXInfo.plist
cd -

cd Sources/MapboxNavigation/
cp Info.plist MBXInfo.plist
plutil -replace CFBundleName -string 'MapboxNavigation' MBXInfo.plist
cd -

step "Updating changelog to version ${SHORT_VERSION}…"

sed -i '' -E "s/## *main/## ${SHORT_VERSION}/g" CHANGELOG.md

# Skip updating the installation instructions for patch releases or prereleases.
if [[ $SHORT_VERSION == $SEM_VERSION && $SHORT_VERSION == *.0 ]]; then
    step "Updating readmes to version ${SEM_VERSION}…"
    sed -i '' -E "s/~> *[^']+/~> ${MINOR_VERSION}/g; s/from: \"*[^\"]+/from: \"${SEM_VERSION}/g; s/\`[^\`]+\` as the minimum version/\`${SEM_VERSION}\` as the minimum version/g" README.md custom-navigation.md
elif [[ $SHORT_VERSION != $SEM_VERSION ]]; then
    step "Updating readmes to version ${SEM_VERSION}…"
    sed -i '' -E "s/:tag => 'v[^']+'/:tag => 'v${SEM_VERSION}'/g; s/\"mapbox\/mapbox-navigation-ios\" \"v[^\"]+\"/\"mapbox\/mapbox-navigation-ios\" \"v${SEM_VERSION}\"/g; s/\.exact\\(\"*[^\"]+/.exact(\"${SEM_VERSION}/g" README.md custom-navigation.md
fi

step "Updating copyright year to ${YEAR}…"

sed -i '' -E "s/© ([0-9]{4})[–-][0-9]{4}/© \\1–${YEAR}/g" LICENSE.md docs/jazzy.yml
