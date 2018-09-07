## Building your own custom navigation UI

_⚠️Warning: this page is for advanced use cases only and is not necessary for most users⚠️_

The Mapbox Navigation SDK is comprised of two modules:

* MapboxCoreNavigation - responsible for rerouting, snapping, progress updates etc.
* MapboxNavigation - responsible for everything UI related.

If the UI provided by MapboxNavigation is not something that can work for your project, it is possible to create a custom navigation experience built on top of MapboxCoreNavigation directly. Note, this is not ideal as it will be a lot of work for the developer. If there is something missing from the UI or not optimal, feel free to open a ticket instead of venturing down this path.

The installation process is very similar to install MapboxNavigation:

### Installing MapboxCoreNavigation

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/MapboxCoreNavigation.svg)](https://cocoapods.org/pods/MapboxCoreNavigation/)

To install Mapbox Core Navigation using [CocoaPods](https://cocoapods.org/):

1. Specify the following dependency in your Podfile:
   ```ruby
   pod 'MapboxCoreNavigation', '~> 0.20'
   ```

1. Run `pod install` and open the resulting Xcode workspace.

Note, you may need to run `pod repo update` before `pod install` if your Cocoapods sources haven't been updated in a while.

Alternatively, to install Mapbox Core Navigation using [Carthage](https://github.com/Carthage/Carthage/) v0.19.0 or above:

1. Specify the following dependency in your Cartfile:
   ```cartfile
   github "mapbox/mapbox-navigation-ios" ~> 0.20
   ```

1. Run `carthage update --platform iOS` to build just the iOS dependencies.

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include MapboxCoreNavigation.framework.
