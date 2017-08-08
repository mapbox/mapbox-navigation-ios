#!/usr/bin/env bash

set -e
set -o pipefail
set -u

if [ -z `which jazzy` ]; then
    echo "Installing jazzy…"
    gem install jazzy
    if [ -z `which jazzy` ]; then
        echo "Unable to install jazzy. See https://github.com/mapbox/mapbox-gl-native/blob/master/platform/ios/INSTALL.md"
        exit 1
    fi
fi


OUTPUT=${OUTPUT:-documentation}

BRANCH=$( git describe --tags --match=v*.*.* --abbrev=0 )
SHORT_VERSION=$( echo ${BRANCH} | sed 's/^v//' )
RELEASE_VERSION=$( echo ${SHORT_VERSION} | sed -e 's/^v//' -e 's/-.*//' )

DEFAULT_THEME="docs/theme"
THEME=${JAZZY_THEME:-$DEFAULT_THEME}

BASE_URL="https://www.mapbox.com/mapbox-navigation-ios"

# Link to directions documentation
DIRECTIONS_VERSION="0.9.1"
DIRECTIONS_SYMBOLS="Directions|Route|RouteStep|RouteLeg|RouteOptions|Waypoint"

rm -rf ${OUTPUT}
mkdir -p ${OUTPUT}

cp -r docs/img "${OUTPUT}"

jazzy \
    --podspec MapboxNavigation-Documentation.podspec \
    --config docs/jazzy.yml \
    --sdk iphonesimulator \
    --module-version ${SHORT_VERSION} \
    --github-file-prefix "https://github.com/mapbox/mapbox-navigation-ios/tree/${BRANCH}" \
    --documentation=docs/guides/*.md \
    --root-url "${BASE_URL}/navigation/${RELEASE_VERSION}/" \
    --theme ${THEME} \
    --output ${OUTPUT}

REPLACE_REGEXP='s/MapboxNavigation\s+(Docs|Reference)/Mapbox Navigation SDK for iOS $1/, '
REPLACE_REGEXP+='s/BRANDLESS_DOCSET_TITLE/Navigation SDK for iOS $1/, '
REPLACE_REGEXP+="s/<span class=\"kt\">(${DIRECTIONS_SYMBOLS})<\/span>/<span class=\"kt\"><a href=\"${BASE_URL//\//\\/}\/directions\/${DIRECTIONS_VERSION}\/Classes\/\$1.html\">\$1<\/a><\/span>/, "

find ${OUTPUT} -name *.html -exec \
    perl -pi -e "$REPLACE_REGEXP" {} \;