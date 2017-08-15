# Installation

## CocoaPods

To install Mapbox Navigation using [CocoaPods](https://cocoapods.org/):

1. Specify the following dependency in your Podfile:
   ```ruby
   pod 'MapboxNavigation', '~> 0.6.1'
   ```
1. Run `pod install` and open the resulting Xcode workspace.

**Note, you may need to run `pod repo update` before `pod install` if your Cocoapods sources haven't been updated in a while.**

## Carthage

Note, [Carthage](https://github.com/Carthage/Carthage/) v0.19.0 or above is required.

1. Specify the following dependency in your Cartfile:
   ```cartfile
   github "mapbox/mapbox-navigation-ios" ~> 0.6.1
   ```
1. Run `carthage update --platform iOS` to build just the iOS dependencies.
1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include MapboxNavigation.framework and MapboxCoreNavigation.framework.

Mapbox Navigation requires a few additions to your `Info.plist`. Be sure to sign up or log in to your Mapbox account and grab a [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/).

1. Add a `MGLMapboxAccessToken` key and paste your [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/)
1. Add a `NSLocationWhenInUseUsageDescription` key if you haven't already
1. If you need voice guidance while your app is in the background, you'll also need to add the `audio` and `location` value to the `UIBackgroundModes` array. You can also do this by navigating to the `Capabilities` tab -> `Background Modes` and enabling the following:
    - `Audio, AirPlay, and Picture in Picture`
    - `Location updates`


## Required Info.plist Keys

Mapbox Navigation requires a few additions to your `Info.plist`. Be sure to sign up or log in to your Mapbox account and grab a [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/).

1. Add a `MGLMapboxAccessToken` key and paste your [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/)
1. Add a `NSLocationWhenInUseUsageDescription` key if you haven't already
1. If you need voice guidance while your app is in the background, you'll also need to add the `audio` and `location` value to the `UIBackgroundModes` array. You can also do this by navigating to the `Capabilities` tab -> `Background Modes` and enabling the following:
    - `Audio, AirPlay, and Picture in Picture`
    - `Location updates`


Next, run the [example app](./run-example-app.html).
