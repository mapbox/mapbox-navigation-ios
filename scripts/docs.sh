#!/usr/bin/env bash

set -e
set -o pipefail
set -u

if [ -z `which jazzy` ]; then
    echo "Installing jazzy…"
    gem install jazzy
    if [ -z `which jazzy` ]; then
        echo "Unable to install jazzy."
        exit 1
    fi
fi


BRANCH=$( git describe --tags --abbrev=0 )
SHORT_VERSION=$( echo ${BRANCH} | sed 's/^ios-v//' )
RELEASE_VERSION=$( echo ${SHORT_VERSION} | sed -e 's/^ios-v//' -e 's/-.*//' )

for module in MapboxNavigation MapboxCoreNavigation
do
    jazzy \
        --config jazzy.yml \
        --module $module \
        --module-version $SHORT_VERSION \
        --root-url https://www.mapbox.com/navigation-sdk/ios/${RELEASE_VERSION}/ \
        --github-file-prefix https://github.com/mapbox/navigation-sdk/tree/${BRANCH} \
        --umbrella_header "$module"/"$module".h \
        --output docs/"$module"
done
