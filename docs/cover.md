# [Mapbox Navigation SDK for iOS](https://www.mapbox.com/ios-sdk/navigation/)

<img alt="Mapbox Navigation SDK" src="./img/navigation.png" width="272" style="margin: auto;display: block;" />

The Mapbox Navigation SDK gives you all the tools you need to add turn-by-turn navigation to your application. It takes just a few minutes to drop a full-fledged turn-by-turn navigation view controller into your application. Or use the Core Navigation framework directly to build something truly custom.

The Mapbox Navigation SDK and Core Navigation are compatible with applications written in Swift 4 or Objective-C in Xcode 9.0. The Mapbox Navigation and Mapbox Core Navigation frameworks run on iOS 9.0 and above.

## Installation

### Using CocoaPods

To install Mapbox Navigation using [CocoaPods](https://cocoapods.org/):

1. Create a [Podfile](https://guides.cocoapods.org/syntax/podfile.html) with the following specification:
   ```ruby
   pod 'MapboxNavigation', '~> ${MINOR_VERSION}'
   ```

1. Run `pod repo update && pod install` and open the resulting Xcode workspace.

### Using Carthage

Alternatively, to install Mapbox Navigation using [Carthage](https://github.com/Carthage/Carthage/):

1. Create a [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#binary-only-frameworks) with the following dependency:
   ```cartfile
   github "mapbox/mapbox-navigation-ios" ~> ${MINOR_VERSION}
   ```

1. Run `carthage update --platform iOS` to build just the iOS dependencies.

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include MapboxNavigation.framework and MapboxCoreNavigation.framework.

## Configuration

1. Mapbox APIs and vector tiles require a Mapbox account and API access token. In the project editor, select the application target, then go to the Info tab. Under the “Custom iOS Target Properties” section, set `MGLMapboxAccessToken` to your access token. You can obtain an access token from the [Mapbox account page](https://www.mapbox.com/account/access-tokens/).

1. In order for the SDK to track the user’s location as they move along the route, set `NSLocationWhenInUseUsageDescription` to:
   > Shows your location on the map and helps improve OpenStreetMap.

1. Users expect the SDK to continue to track the user’s location and deliver audible instructions even while a different application is visible or the device is locked. Go to the Capabilities tab. Under the Background Modes section, enable “Audio, AirPlay, and Picture in Picture” and “Location updates”. (Alternatively, add the `audio` and `location` values to the `UIBackgroundModes` array in the Info tab.)

Now import the relevant modules and present a new `NavigationViewController`. You can also [push to a navigation view controller from within a storyboard](https://www.mapbox.com/ios-sdk/navigation/overview/storyboards/) if your application’s UI is laid out in Interface Builder.

```swift
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
```

```swift
let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House")

let options = NavigationRouteOptions(waypoints: [origin, destination])

Directions.shared.calculate(options) { (waypoints, routes, error) in
    guard let route = routes?.first else { return }

    let viewController = NavigationViewController(for: route)
    present(viewController, animated: true, completion: nil)
}
```

## Starting points

This SDK is divided into two frameworks: the Mapbox Navigation framework (`MapboxNavigation`) is the ready-made turn-by-turn navigation UI, while the Mapbox Core Navigation framework (`MapboxCoreNavigation`) is responsible for the underlying navigation logic.

### Mapbox Navigation

`NavigationViewController` is the main class that encapsulates the entirety of the turn-by-turn navigation UI, orchestrating the map view, various UI elements, and the route controller. Your application would most likely present an instance of this class. The `NavigationViewControllerDelegate` protocol allows your application to customize various aspects of the UI and react to location-related events as they occur.

`NavigationMapView` is the map view at the center of the turn-by-turn navigation UI. You can also use this class independently of `NavigationViewController`, for example to display a route preview map. The `NavigationMapViewDelegate` protocol allows your application to customize various aspects of the map view’s appearance.

`CarPlayManager` is a singleton class that manages the [CarPlay](https://developer.apple.com/carplay/) screen if your application is CarPlay-enabled. It provides a main map for browsing, a search interface powered by [MapboxGeocoder.swift](https://github.com/mapbox/MapboxGeocoder.swift/), and a turn-by-turn navigation UI similar to the one provided by `NavigationViewController`. Your `UIApplicationDelegate` subclass can conform to the `CarPlayManagerDelegate` protocol to manage handoffs between `NavigationViewController` and the CarPlay device, as well as to customize some aspects of the CarPlay navigation experience. To take advantage of CarPlay functionality, your application must have a CarPlay navigation application entitlement and be built in Xcode 10 or above, and the user’s iPhone or iPad must have iOS 12 or above installed.

### Core Navigation

`RouteController` is responsible for receiving user location updates and determining their relation to the route line. If you build a completely custom navigation UI, this is the class your code would interact with directly. The `RouteControllerDelegate` protocol allows your application to react to location-related events as they occur. Corresponding `Notification`s are also posted to the shared `NotificationCenter`. These notifications indicate the current state of the application in the form of a `RouteProgress` object.

For further details, consult the guides and examples included with this API reference. If you have any questions, please see [our help page](https://www.mapbox.com/help/). We welcome your [bug reports, feature requests, and contributions](https://github.com/mapbox/mapbox-navigation-ios/blob/master/CONTRIBUTING.md).
