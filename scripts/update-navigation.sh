#!/usr/bin/env bash

set -e
set -o pipefail
set -u

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT

OUTPUT="/tmp/`uuidgen`"
RELEASE_BRANCH=${1:-master}

step "Updating mapbox-navigation-ios…"
git fetch --depth=1 --prune
git fetch --tags
git checkout $RELEASE_BRANCH
VERSION=$( git describe --tags --match=v*.*.* --abbrev=0 | sed 's/^v//' )

# I don't think mapbox-navigation-ios uses this branch naming convention
# git checkout $VERSION

step "Updating jazzy…"
gem install jazzy

step "Generating new docs for ${VERSION}…"
OUTPUT=${OUTPUT} scripts/document.sh

step "Moving new docs folder to ./$VERSION"
rm -rf "./$VERSION"
mkdir -p "./navigation/api/$VERSION"
mv -v $OUTPUT/* "./navigation/api/$VERSION"

step "Switching branch to publisher-production"
git checkout origin/publisher-production
step "Committing API docs for $VERSION"
git add "./$VERSION"
git commit -m "[navigation] Add Mapbox Directions for Swift API docs for $VERSION [ci skip]" --no-verify

step "Finished updating documentation"
