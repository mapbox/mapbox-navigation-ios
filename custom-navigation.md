## Building your own custom navigation UI

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/MapboxCoreNavigation.svg)](https://cocoapods.org/pods/MapboxCoreNavigation/)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)

_⚠️Warning: this page is for advanced use cases only and is not necessary for most users⚠️_

The Mapbox Navigation SDK is comprised of two modules:

* MapboxCoreNavigation - responsible for rerouting, snapping, progress updates etc.
* MapboxNavigation - responsible for everything UI related.

If the UI provided by MapboxNavigation is not something that can work for your project, it is possible to create a custom navigation experience built on top of MapboxCoreNavigation directly. Note, this is not ideal as it will be a lot of work for the developer. If there is something missing from the UI or not optimal, feel free to open a ticket instead of venturing down this path.

The installation process is very similar to install MapboxNavigation:

### Using CocoaPods

To install Mapbox Core Navigation using [CocoaPods](https://cocoapods.org/):

1. Go to your [Mapbox account dashboard](https://account.mapbox.com/) and create an access token that has the `DOWNLOADS:READ` scope. **PLEASE NOTE: This is not the same as your production Mapbox API token. Make sure to keep it private and do not insert it into any Info.plist file.** Create a file named `.netrc` in your home directory if it doesn’t already exist, then add the following lines to the end of the file:
   ```
   machine api.mapbox.com 
     login mapbox
     password PRIVATE_MAPBOX_API_TOKEN
   ```
   where _PRIVATE_MAPBOX_API_TOKEN_ is your Mapbox API token with the `DOWNLOADS:READ` scope. 

1. Create a [Podfile](https://guides.cocoapods.org/syntax/podfile.html) with the following specification:
   ```ruby
   # Latest stable release
   pod 'MapboxCoreNavigation', '~> 1.3'
   # Latest prerelease
   pod 'MapboxCoreNavigation', :git => 'https://github.com/mapbox/mapbox-navigation-ios.git', :tag => 'v1.3.0-beta.1'
   ```

1. Run `pod repo update && pod install` and open the resulting Xcode workspace.

### Using Carthage

To install Mapbox Navigation using [Carthage](https://github.com/Carthage/Carthage/) v0.35 or above:

1. Go to your [Mapbox account dashboard](https://account.mapbox.com/) and create an access token that has the `DOWNLOADS:READ` scope. **PLEASE NOTE: This is not the same as your production Mapbox API token. Make sure to keep it private and do not insert it into any Info.plist file.** Create a file named `.netrc` in your home directory if it doesn’t already exist, then add the following lines to the end of the file:
   ```
   machine api.mapbox.com
     login mapbox
     password PRIVATE_MAPBOX_API_TOKEN
   ```
   where _PRIVATE_MAPBOX_API_TOKEN_ is your Mapbox API token with the `DOWNLOADS:READ` scope. 

1. _(Optional)_ Clear your Carthage caches:
   ```bash
   rm -rf ~/Library/Caches/carthage/ ~/Library/Caches/org.carthage.CarthageKit/binaries/{MapboxAccounts,MapboxCommon-ios,MapboxNavigationNative}
   ```

1. Create a [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#github-repositories) with the following dependency:
   ```cartfile
   # Latest stable release
   github "mapbox/mapbox-navigation-ios" ~> 1.3
   # Latest prerelease
   github "mapbox/mapbox-navigation-ios" "v1.3.0-beta.1"
   ```

1. Run `./Carthage/Checkouts/mapbox-navigation-ios/scripts/wcarthage.sh bootstrap --platform iOS --cache-builds --use-netrc`. (wcarthage.sh is a temporary replacement for `carthage` to work around [a linker error in Xcode 12](https://github.com/Carthage/Carthage/issues/3019).)

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embed Frameworks build phase should include `MapboxCoreNavigation.framework`, `MapboxNavigationNative.framework`, `MapboxCommon.framework`, and `MapboxAccounts.framework`.

### Using Swift Package Manager

To install the MapboxCoreNavigation framework using [Swift Package Manager](https://swift.org/package-manager/) on the command line:

1. Go to your [Mapbox account dashboard](https://account.mapbox.com/) and create an access token that has the `DOWNLOADS:READ` scope. **PLEASE NOTE: This is not the same as your production Mapbox API token. Make sure to keep it private and do not insert it into any Info.plist file.** Create a file named `.netrc` in your home directory if it doesn’t already exist, then add the following lines to the end of the file:
   ```
   machine api.mapbox.com
     login mapbox
     password PRIVATE_MAPBOX_API_TOKEN
   ```
   where _PRIVATE_MAPBOX_API_TOKEN_ is your Mapbox API token with the `DOWNLOADS:READ` scope. 

1. Run `swift package init` to create a Package.swift, then add the following dependency:
   ```swift
   // Latest stable release
   .package(name: "MapboxCoreNavigation", url: "https://github.com/mapbox/mapbox-navigation-ios.git", from: "1.3.0")
   // Latest prerelease
   .package(name: "MapboxCoreNavigation", url: "https://github.com/mapbox/mapbox-navigation-ios.git", from: "1.3.0")
   ```

### Using Xcode

To install the MapboxCoreNavigation framework using [Swift Package Manager](https://swift.org/package-manager/) within Xcode:

1. Go to your [Mapbox account dashboard](https://account.mapbox.com/) and create an access token that has the `DOWNLOADS:READ` scope. **PLEASE NOTE: This is not the same as your production Mapbox API token. Make sure to keep it private and do not insert it into any Info.plist file.** Create a file named `.netrc` in your home directory if it doesn’t already exist, then add the following lines to the end of the file:
   ```
   machine api.mapbox.com
     login mapbox
     password PRIVATE_MAPBOX_API_TOKEN
   ```
   where _PRIVATE_MAPBOX_API_TOKEN_ is your Mapbox API token with the `DOWNLOADS:READ` scope. 

1. In Xcode, go to File ‣ Swift Packages ‣ Add Package Dependency.

1. Enter `https://github.com/mapbox/mapbox-navigation-ios.git` as the package repository and click Next.

1. Set Rules to Version, Up to Next Major, and enter `1.3.0` as the minimum version requirement. Click Next.
