# This script helps to keep the navigation SDK’s developers from exposing their own access tokens during development.
# See <https://www.mapbox.com/help/ios-private-access-token/> for more information. If you are developing an application privately,
# you may add the MBXAccessToken key directly to your Info.plist file and delete Apply Mapbox Access Token
# Run Script Phase in Build Phases.
token_file=~/.mapbox
token_file2=~/mapbox
token="$(cat $token_file 2>/dev/null || cat $token_file2 2>/dev/null)"
if [ "$token" ]; then
  plutil -replace MBXAccessToken -string $token "$TARGET_BUILD_DIR/$INFOPLIST_PATH"
else
  echo 'warning: Missing Mapbox access token'
  open 'https://www.mapbox.com/account/access-tokens/'
  echo "warning: Get an access token from <https://www.mapbox.com/account/access-tokens/>, then create a new file at $token_file or $token_file2 that contains the access token."
fi
