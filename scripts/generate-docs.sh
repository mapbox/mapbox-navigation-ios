#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <documentation_version> <output_directory>"
    echo "Example: $0 2.20.3 build/docs/2.20.3"
    exit 1
fi

SHORT_VERSION=$1
OUTPUT=$2

if [[ ! "${SHORT_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-.+)?$ ]]; then
    echo "Error: Version '${SHORT_VERSION}' does not match the required format."
    echo "Format: X.Y.Z or X.Y.Z-suffix (e.g., 2.20.3, 2.21.0-beta.1)"
    exit 1
fi

# Safety checks for output directory
ABS_PWD=$(pwd -P)
if [[ "$OUTPUT" == /* ]]; then
    # Absolute path
    if [[ "$OUTPUT" != "$ABS_PWD"* ]]; then
        echo "Error: Output directory '$OUTPUT' must be within the current working directory '$ABS_PWD'."
        exit 1
    fi
else
    # Relative path
    if [[ "$OUTPUT" == *".."* ]]; then
         echo "Error: Output directory '$OUTPUT' cannot contain parent directory traversal ('..')."
         exit 1
    fi
fi

if [[ "${OUTPUT}" == "/" ]] || [[ "${OUTPUT}" == "${HOME}" ]]; then
    echo "Error: Output directory cannot be root or home directory."
    exit 1
fi

bundle check || bundle install

SOURCEKITTEN_PATH="$(dirname "$(bundle exec gem which jazzy)")/../bin/sourcekitten"

if [[ -z $(which "${SOURCEKITTEN_PATH}") ]]; then
    echo "Unable to locate SourceKitten. See installation instructions at https://github.com/jpsim/SourceKitten#installation"
    exit 1
fi

RELEASE_VERSION=$( echo ${SHORT_VERSION} | sed -e 's/-.*//' )
MINOR_VERSION=$( echo ${SHORT_VERSION} | grep -Eo '^\d+\.\d+' )
LONG_VERSION="v${SHORT_VERSION}"

DEFAULT_THEME="docs/theme"
THEME=${JAZZY_THEME:-$DEFAULT_THEME}

BASE_URL="https://docs.mapbox.com/ios"

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
"${SOURCEKITTEN_PATH}" doc --module-name MapboxCoreNavigation -- -project "${PROJECT}" -destination "${DESTINATION}" -scheme MapboxCoreNavigation > core.json
"${SOURCEKITTEN_PATH}" doc --module-name MapboxNavigation -- -project "${PROJECT}" -destination "${DESTINATION}" -scheme MapboxNavigation > ui.json

bundle exec jazzy \
    --config docs/jazzy.yml \
    --sdk iphonesimulator \
    --github-file-prefix "https://github.com/mapbox/mapbox-navigation-ios/tree/${LONG_VERSION}" \
    --readme ${README} \
    --documentation="docs/guides/*.md" \
    --root-url "${BASE_URL}/navigation/api/${RELEASE_VERSION}/" \
    --theme ${THEME} \
    --output ${OUTPUT} \
    --module_version ${RELEASE_VERSION} \
    --sourcekitten-sourcefile core.json,ui.json \
    2>&1 | tee docs.output
    
rm core.json ui.json

# Filter out known harmless warnings (needed for Xcode 15+)
sed -i '' '/`AppKit` has no USR/d' docs.output

if egrep -e "(WARNING)|(USR)" docs.output; then
    echo "Please eliminate Jazzy warnings"
    exit 1
fi
    
rm docs.output

# Link to directions documentation
DIRECTIONS_VERSION=$(python3 -c "import json; print(list(filter(lambda x:x['package']=='MapboxDirections', json.loads(open('Package.resolved').read())['object']['pins']))[0]['state']['version'])")
python3 scripts/postprocess-docs.py -b "${BASE_URL}/directions/api/${DIRECTIONS_VERSION}" -d "${OUTPUT}"

echo $SHORT_VERSION > $OUTPUT/latest_version
