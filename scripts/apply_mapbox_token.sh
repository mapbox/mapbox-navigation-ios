#!/bin/sh

set -e

token="$(cat ~/.mapbox 2>/dev/null || cat ~/mapbox 2>/dev/null)"

if [ -z "$token" ]; then
  echo 'warning: Missing Mapbox access token'
  echo "warning: Get an access token from <https://www.mapbox.com/account/access-tokens/>, then create a new file at ~/.mapbox that contains the access token."
  exit 1
fi

INFO_PLIST_PATH="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
echo "Updating ${INFO_PLIST_PATH} with Mapbox token"

if [ ! -f ${INFO_PLIST_PATH} ]; then
  echo "error: Could not find Info.plist at ${INFO_PLIST_PATH}"
  exit 1
fi

plutil -replace 'MBXAccessToken' -string "$token" "${INFO_PLIST_PATH}"
