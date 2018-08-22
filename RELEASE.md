# Release Process

### Code level changes

1. Create a new branch.
1. Update the internal and marketing version: `agvtool next-version -all && agvtool new-marketing-version $VERSION_NUMBER`.
1. Update `*.podspec` to appropriate new version.
1. If this is a minor version, update versions in README.md and custom-navigation.md.
1. In `CHANGELOG.md`, update `master` to the new version.
1. Create a new PR.

### Document

1. Once the PR is merged, pull master locally.
1. Create a new tag, example: `git tag v0.16.0`.
1. Do not push the tag quite yet.
1. Follow directions for updating the [documentation](https://github.com/mapbox/mapbox-navigation-ios/blob/master/docs/README.md).
    * Make sure these files are updated to the appropriate version:
        * https://github.com/mapbox/mapbox-navigation-ios/blob/mb-pages/latest_version
        * https://github.com/mapbox/mapbox-navigation-ios/tree/mb-pages/navigation/docsets
        * https://github.com/mapbox/mapbox-navigation-ios/blob/mb-pages/navigation/index.html
1. Push documentation changes. _(These changes are pushed to the `mb-pages` branch)_
1. Push the tag: `git push origin v0.16.1`.

### Making the releases

1. Go to https://github.com/mapbox/mapbox-navigation-ios/releases
1. Click `Draft a new release`
1. In the `Tag version` dropdown, select the new tag you pushed.
1. Copy the changes from `CHANGELOG.md`.
1. Prepend the changes with: `[Changes](https://github.com/mapbox/mapbox-navigation-ios/compare/v0.16.0...v0.16.1) since [v0.16.0](https://github.com/mapbox/mapbox-navigation-ios/releases/tag/v0.16.0):`
1. Append the changes with `Documentation is [available online](https://www.mapbox.com/mapbox-navigation-ios/navigation/0.16.1) or within Xcode.`
1. Make sure you are using the appropriate version number

### Pushing to CocoaPods

⚠️ Important: Order matters here ⚠️

1. Update pods: `pod repo update`
1. Push MapboxCoreNavigation: `pod trunk push MapboxCoreNavigation.podspec`
1. Update pods: `pod repo update`
1. Push MapboxNavigation: `pod trunk push MapboxNavigation.podspec`

### Next steps

1. Run `pod update` in the [examples repository](https://github.com/mapbox/navigation-ios-examples/) (and edit the Podfile if necessary) to install the latest version.
1. See [this wiki page](https://github.com/mapbox/navigation/wiki/Releasing-the-iOS-navigation-SDK) for information on updating Mapbox documentation.
