#!/usr/bin/env bash

set -e
set -o pipefail
set -u

bundle check || bundle install

BRANCH=$( git describe --tags --match=v*.*.* --abbrev=0 )
SHORT_VERSION=$( echo ${BRANCH} | sed 's/^v//' )
RELEASE_VERSION=$( echo ${SHORT_VERSION} | sed -e 's/-.*//' )
MINOR_VERSION=$( echo ${SHORT_VERSION} | grep -Eo '^\d+\.\d+' )

OUTPUT=${OUTPUT:-${SHORT_VERSION:-documentation}}

DEFAULT_THEME="docs/theme"
THEME=${JAZZY_THEME:-$DEFAULT_THEME}

BASE_URL="https://docs.mapbox.com/ios"

# Link to directions documentation
DIRECTIONS_VERSION=$(grep 'mapbox-directions-swift' Cartfile.resolved | grep -oE '"v.+?"' | grep -oE '[^"v]+')
DIRECTIONS_SYMBOLS="AttributeOptions|CoordinateBounds|Directions|DirectionsCredentials|DirectionsOptions|DirectionsPriority|DirectionsProfileIdentifier|DirectionsResult|Intersection|Lane|LaneIndication|MapMatchingResponse|Match|MatchOptions|RoadClasses|Route|RouteLeg|RouteOptions|RouteResponse|RouteStep|SpokenInstruction|Tracepoint|VisualInstruction|VisualInstruction.Component|VisualInstruction.Component.ImageRepresentation|VisualInstruction.Component.TextRepresentation|VisualInstructionBanner|Waypoint"

rm -rf ${OUTPUT}
mkdir -p ${OUTPUT}

cp -r docs/img "${OUTPUT}"

rm -rf /tmp/mbnavigation
mkdir -p /tmp/mbnavigation/
README=/tmp/mbnavigation/README.md
cp docs/cover.md "${README}"
perl -pi -e "s/\\$\\{MINOR_VERSION\\}/${MINOR_VERSION}/" "${README}"
perl -pi -e "s/\\$\\{SHORT_VERSION\\}/${SHORT_VERSION}/" "${README}"
# http://stackoverflow.com/a/4858011/4585461
echo "## Changes in version ${RELEASE_VERSION}" >> "${README}"
sed -n -e '/^## /{' -e ':a' -e 'n' -e '/^## /q' -e 'p' -e 'ba' -e '}' CHANGELOG.md >> "${README}"
    
PROJECT="MapboxNavigation-SPM.xcodeproj"
DESTINATION="generic/platform=iOS"
sourcekitten doc --module-name MapboxCoreNavigation -- -project "${PROJECT}" -destination "${DESTINATION}" -scheme MapboxCoreNavigation > core.json
sourcekitten doc --module-name MapboxNavigation -- -project "${PROJECT}" -destination "${DESTINATION}" -scheme MapboxNavigation > ui.json

bundle exec jazzy \
    --config docs/jazzy.yml \
    --sdk iphonesimulator \
    --github-file-prefix "https://github.com/mapbox/mapbox-navigation-ios/tree/${BRANCH}" \
    --readme ${README} \
    --documentation="docs/guides/*.md" \
    --root-url "${BASE_URL}/navigation/api/${RELEASE_VERSION}/" \
    --theme ${THEME} \
    --output ${OUTPUT} \
    --module_version ${RELEASE_VERSION} \
    --sourcekitten-sourcefile core.json,ui.json \
    2>&1 | tee docs.output
    
if egrep -e "(WARNING)|(USR)" docs.output; then
    echo "Please eliminate Jazzy warnings"
    exit 1
fi
    
rm core.json ui.json

REPLACE_REGEXP='s/MapboxNavigation\s+(Docs|Reference)/Mapbox Navigation SDK for iOS $1/, '
REPLACE_REGEXP+="s/<span class=\"kt\">(${DIRECTIONS_SYMBOLS})<\/span>/<span class=\"kt\"><a href=\"${BASE_URL//\//\\/}\/directions\/api\/${DIRECTIONS_VERSION}\/Classes\/\$1.html\">\$1<\/a><\/span>/, "

find ${OUTPUT} -name *.html -exec \
    perl -pi -e "$REPLACE_REGEXP" {} \;

echo $SHORT_VERSION > $OUTPUT/latest_version
