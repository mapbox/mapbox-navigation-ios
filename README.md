# Mapbox Navigation SDK for iOS

[![Build Status](https://www.bitrise.io/app/6fc45a7e2817b859.svg?token=XTgNMVxObhd8w8EmsAgJ1Q&branch=master)](https://www.bitrise.io/app/6fc45a7e2817b859)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/MapboxNavigation.svg)](https://cocoapods.org/pods/MapboxNavigation/)

![Mapbox Navigation SDK](https://github.com/mapbox/mapbox-navigation-ios/raw/master/docs/img/navigation.png)

Mapbox Navigation gives you all the tools you need to add turn-by-turn navigation to your apps.

Get up and running in a few minutes with our drop-in turn-by-turn navigation `NavigationViewController`, or build a completely custom turn-by-turn navigation app with our core components for routing and navigation.

## Features

- Drop-in turn-by-turn navigation UI
- Automotive, cycling, and walking directions
- Traffic avoidance
- Maneuver announcements
- Text instructions
- Text to speech support via AVSpeechSynthesizer or Amazon Polly
- Automatic rerouting
- Snap to route

## [Documentation](https://mapbox.github.io/mapbox-navigation-ios/navigation/)

## Installation

To install Mapbox Navigation using [Carthage](https://github.com/Carthage/Carthage/) v0.19.0 or above:

1. Specify the following dependency in your Cartfile:
   ```cartfile
   github "mapbox/mapbox-navigation-ios" ~> 0.4.0
   ```

1. Run `carthage update --platform iOS` to build just the iOS dependencies.

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include MapboxNavigation.framework and MapboxCoreNavigation.framework.

Alternatively, to install Mapbox Navigation using [CocoaPods](https://cocoapods.org/):

1. Specify the following dependency in your Podfile:
   ```ruby
   pod 'MapboxNavigation', '~> 0.4.0'
   ```
1. Run `pod install` and open the resulting Xcode workspace.

Note, you may need to run `pod repo update` before `pod install` if your Cocoapods sources haven't been updated in a while.

### Running the example project

1. Clone the repository or download the [.zip file](https://github.com/mapbox/mapbox-navigation-ios/archive/master.zip)
1. Run `carthage update --platform ios` to build just the iOS dependencies
1. Open `MapboxNavigation.xcodeproj`
1. Sign up or log in to your Mapbox account and grab a [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/)
1. Open the `Info.plist` for either `Example-Swift` or `Example-Objective-C` and paste your [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/) into `MGLMapboxAccessToken`
1. Build and run the `Example-Swift` or `Example-Objective-C` target

## Usage

**[API reference](https://mapbox.github.io/mapbox-navigation-ios/navigation/)**

```swift
import MapboxDirections
import MapboxNavigation
```

```swift
let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House")

let options = RouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
options.routeShapeResolution = .full
options.includesSteps = true

Directions.shared.calculate(options) { (waypoints, routes, error) in
    guard let route = routes?.first else { return }

    let viewController = NavigationViewController(for: route)
    self.present(viewController, animated: true, completion: nil)
}
```

#### Required Info.plist Keys
Mapbox Navigation requires a few additions to your `Info.plist`. Be sure to sign up or log in to your Mapbox account and grab a [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/).

1. Add a `MGLMapboxAccessToken` key and paste your [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/)
1. Add a `NSLocationWhenInUseUsageDescription` key if you haven't already
1. If you need voice guidance while your app is in the background, you'll also need to add the `audio` and `location` value to the `UIBackgroundModes` array. You can also do this by navigating to the `Capabilities` tab -> `Background Modes` and enabling the following:
    - `Audio, AirPlay, and Picture in Picture`
    - `Location updates`

#### Storyboards

See [this guide](https://github.com/mapbox/mapbox-navigation-ios/blob/master/docs/Storyboards.md) for usage with storyboards.

## Building your own custom navigation UI

If you need additional flexibility, you can use the following building blocks to build your own custom navigation UI:

* [Interactive map SDK for iOS](https://www.mapbox.com/ios-sdk/) and [macOS](https://mapbox.github.io/mapbox-gl-native/macos/)
* [Mapbox Studio](https://www.mapbox.com/studio/)
  * Design custom maps with live traffic overlays
* [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift) (also compatible with macOS, tvOS, and watchOS)
  * Automotive, cycling, and walking directions
  * Traffic-influenced driving directions
* Mapbox Core Navigation (`MapboxCoreNavigation` module) (also compatible with watchOS)
  * Route controller
    * Progress calculations
    * Location snapping
  * Guidance notifications
    * Current progress along a route
    * Departure and arrival notifications
    * Upcoming maneuver notifications
    * Rerouting notifications
  * Geometry functions
  * Distance formatter
* [OSRM Text Instructions for Swift](https://github.com/Project-OSRM/osrm-text-instructions.swift/) (also compatible with macOS, tvOS, and watchOS)
  * Localized guidance instructions

### Installing Mapbox Core Navigation

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/MapboxCoreNavigation.svg)](https://cocoapods.org/pods/MapboxCoreNavigation/)

To install Mapbox Core Navigation using [Carthage](https://github.com/Carthage/Carthage/) v0.19.0 or above:

1. Specify the following dependency in your Cartfile:
   ```cartfile
   github "mapbox/mapbox-navigation-ios" ~> 0.4.0
   ```

1. Run `carthage update --platform iOS` to build just the iOS dependencies.

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include MapboxCoreNavigation.framework.

Alternatively, to install Mapbox Core Navigation using [CocoaPods](https://cocoapods.org/):

1. Specify the following dependency in your Podfile:
   ```ruby
   pod 'MapboxCoreNavigation', '~> 0.4.0'
   ```

1. Run `pod install` and open the resulting Xcode workspace.
