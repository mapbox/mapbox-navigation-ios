# Mapbox Navigation SDK for iOS

[![Build Status](https://www.bitrise.io/app/6fc45a7e2817b859.svg?token=XTgNMVxObhd8w8EmsAgJ1Q&branch=master)](https://www.bitrise.io/app/6fc45a7e2817b859)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/MapboxNavigation.svg)](https://cocoapods.org/pods/MapboxNavigation/)

<img alt="Mapbox Navigation SDK" src="https://github.com/mapbox/mapbox-navigation-ios/raw/master/docs/img/navigation.png" width="50%" style="margin: auto;display: block;" />

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

## [Documentation](https://www.mapbox.com/mapbox-navigation-ios/navigation/)

## Requirements:
* \>= Xcode 9
* Swift 4. If you'd like to use Swift 3.2, the last supported release is v0.10.1.

## Installation

To install Mapbox Navigation using [CocoaPods](https://cocoapods.org/):

1. Specify the following dependency in your Podfile:
   ```ruby
   pod 'MapboxNavigation', '~> 0.13'
   ```
1. Run `pod install` and open the resulting Xcode workspace.

Note, you may need to run `pod repo update` before `pod install` if your Cocoapods sources haven't been updated in a while.

Alternatively, to install Mapbox Navigation using [Carthage](https://github.com/Carthage/Carthage/) v0.19.0 or above:

1. Specify the following dependency in your Cartfile:
   ```cartfile
   github "mapbox/mapbox-navigation-ios" ~> 0.13
   ```

1. Run `carthage update --platform iOS` to build just the iOS dependencies.

1. Follow the rest of [Carthage’s iOS integration instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). Your application target’s Embedded Frameworks should include MapboxNavigation.framework and MapboxCoreNavigation.framework.



### Running the example project

1. Clone the repository or download the [.zip file](https://github.com/mapbox/mapbox-navigation-ios/archive/master.zip)
1. Run `carthage update --platform ios` to build just the iOS dependencies.
1. Open `MapboxNavigation.xcodeproj`.
1. Sign up or log in to your Mapbox account and grab a [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/).
1. Open the Info.plist for either `Example-Swift` or `Example-Objective-C` and paste your [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/) into `MGLMapboxAccessToken`. (Alternatively, if you plan to use this project as the basis for a public project on GitHub, place the access token in a plain text file named `.mapbox` or `mapbox` in your home directory instead of adding it to Info.plist.)
1. Build and run the `Example-Swift` or `Example-Objective-C` target.

## Usage

**[API reference](https://www.mapbox.com/mapbox-navigation-ios/navigation/)**

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
    self.present(viewController, animated: true, completion: nil)
}
```

**The [example app](https://github.com/mapbox/mapbox-navigation-ios/blob/master/Examples/Swift/ViewController.swift) is also a great resource for referencing various APIs.**

## More Examples

Looking for more examples and use cases on how to the Mapbox Navigation SDK? Check out our example repository, [mapbox/navigation-ios-examples](https://github.com/mapbox/navigation-ios-examples).

#### Required Info.plist Keys
Mapbox Navigation requires a few additions to your `Info.plist`. Be sure to sign up or log in to your Mapbox account and grab a [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/).

1. Add a `MGLMapboxAccessToken` key and paste your [Mapbox Access Token](https://www.mapbox.com/studio/account/tokens/)
1. Add a `NSLocationWhenInUseUsageDescription` key if you haven't already
1. If you need voice guidance while your app is in the background, you'll also need to add the `audio` and `location` value to the `UIBackgroundModes` array. You can also do this by navigating to the `Capabilities` tab -> `Background Modes` and enabling the following:
    - `Audio, AirPlay, and Picture in Picture`
    - `Location updates`

#### Styling

You can customize the appearance in order to blend in with the rest of your app. Checkout [`DayStyle.swift`](https://github.com/mapbox/mapbox-navigation-ios/blob/master/MapboxNavigation/DayStyle.swift) for all styleable elements.

```swift
class CustomStyle: DayStyle {

    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .nightStyle
    }

    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .orange
    }
}
```

then initialize `NavigationViewController` with your style or styles:

```swift
NavigationViewController(for: route, styles: [CustomStyle()])
```

#### NavigationViewController Delegate Methods

* `navigationViewController:didArriveAtDestination:`: Fired when the user arrives at their destination. You are responsible for dismissing the UI.
* `navigationViewControllerDidCancelNavigation`: Fired when the user taps `Cancel`. You are responsible for dismissing the UI.
* `navigationViewController:shouldRerouteFromLocation:`: Fired when SDK detects that a user has gone off route. You can return `false` here to either prevent a reroute from occuring or if you want to rerequest an alternative route manually.
* `navigationViewController:willRerouteFromLocation:`: Fired just before the SDK requests a new route.
* `navigationViewController:didRerouteAlongRoute:`: Fired as soon as the SDK receives a new route.
* `navigationViewController:didFailToRerouteWithError:`: Fired when SDK receives an error instead of a new route.

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

### Route Controller

`RouteController` is given a route. Internally `RouteController` matches the user's current location to the route while looking at 3 principle pieces:

1. Is the user on or off the route?
1. How far along the step is the user?
1. Does the user need to be alerted about an upcoming maneuver?

The library compares the user from the route and decides upon each one of these parameters and acts accordingly. The developer is told what is happening behind the scenes via notifications.

### Guidance Notifications

This library relies heavily on notifications for letting the developer know when events have occurred.

#### `.routeControllerProgressDidChange`

* Emitted when the user moves along the route. Notification contains 3 keys:
  * `RouteControllerProgressDidChangeNotificationProgressKey` - `RouteProgress` - Current progress along route
  * `RouteControllerProgressDidChangeNotificationLocationKey` - `CLLocation` - Current location
  * `RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey` - `Double` - Given users speed and location, this is the number of seconds left to the end of the step

#### `.routeControllerDidPassSpokenInstructionPoint`

* Emitted when user passes a point where instructions should be spoken. This indicates the user should be notified about the upcoming maneuver. You can find the instruction narrative in the `RouteProgress` object. Notification contains 1 key:
  * `RouteControllerDidPassSpokenInstructionPointRouteProgressKey` - `RouteProgress` - Current progress along route

#### `.routeControllerShouldReroute`

* Emitted when the user is off the route and should be rerouted. Notification contains 1 key:
  * `RouteControllerNotificationShouldRerouteKey` - `CLLocation` - Last location of user

Looking for a more advanced use case? See our installation guide of [MapboxCoreNavigation](./custom-navigation.md).

## Language support

See [languages.md](./languages.md) for more information.

## Contributing

We welcome feedback and code contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

## License

Mapbox Navigation SDK for iOS is released under the ISC License. See [LICENSE.md](https://github.com/mapbox/mapbox-navigation-ios/blob/master/LICENSE.md) for details.
