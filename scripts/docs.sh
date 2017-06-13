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

for module in MapboxNavigation MapboxCoreNavigation
do
    jazzy \
        --config jazzy.yml \
        --module "$module" \
        --module-version 0.4.0 \
        --root-url 'https://www.mapbox.com/navigation-sdk/ios/0.4.0/' \
        --github-file-prefix 'https://github.com/mapbox/mapbox-navigation-ios/tree/master' \
        --umbrella_header "$module"/"$module".h \
        --output docs/"$module"
done
