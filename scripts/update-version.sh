#!/usr/bin/env bash

set -e
set -o pipefail
set -u

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
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

xcrun agvtool bump -all
xcrun agvtool new-marketing-version "${SHORT_VERSION}"

step "Updating CocoaPods podspecs to version ${SEM_VERSION}…"

find . -type f -name '*.podspec' -exec sed -i '' "s/^ *s.version *=.*$/  s.version = '${SEM_VERSION}'/" {} +

step "Updating CocoaPods installation test fixture…"

cd MapboxCoreNavigationTests/CocoaPodsTest/PodInstall/
pod update
cd -

step "Updating changelog to version ${SHORT_VERSION}…"

sed -i '' -E "s/## *main/## ${SHORT_VERSION}/g" CHANGELOG.md

# Skip updating the installation instructions for patch releases or prereleases.
if [[ $SHORT_VERSION == $SEM_VERSION && $SHORT_VERSION == *.0 ]]; then
    step "Updating readmes to version ${SEM_VERSION}…"
    sed -i '' -E "s/~> *[^']+/~> ${MINOR_VERSION}/g" README.md custom-navigation.md
elif [[ $SHORT_VERSION != $SEM_VERSION ]]; then
    step "Updating readmes to version ${SEM_VERSION}…"
    sed -i '' -E "s/:tag => 'v[^']+'/:tag => 'v${SEM_VERSION}'/g; s/\"mapbox\/mapbox-navigation-ios\" \"v[^\"]+\"/\"mapbox\/mapbox-navigation-ios\" \"v${SEM_VERSION}\"/g" README.md custom-navigation.md
fi

step "Updating copyright year to ${YEAR}…"

sed -i '' -E "s/© ([0-9]{4})[–-][0-9]{4}/© \\1–${YEAR}/g" LICENSE.md docs/jazzy.yml
