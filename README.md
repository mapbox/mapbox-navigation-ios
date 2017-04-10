# Mapbox Navigation SDK for iOS

![Mapbox Navigation SDK](https://cloud.githubusercontent.com/assets/764476/23636459/567771d2-028a-11e7-95cf-a8832792c67a.png) ![](https://cloud.githubusercontent.com/assets/764476/23671279/883c63ae-031f-11e7-8396-b404d18881e1.png)

Mapbox Navigation gives you all the tools you need to add turn-by-turn navigation to your apps.

Get up and running in a few minutes with our drop-in turn-by-turn navigation `RouteViewController`, or build a completely custom turn-by-turn navigation app with our core components for routing and navigation.

[![Build Status](https://www.bitrise.io/app/2f82077d3f083479.svg?token=mC783nGMKA3XrvcMCJAOLg&branch=master)](https://www.bitrise.io/app/2f82077d3f083479)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Features

- Drop-in turn-by-turn navigation UI
- Automotive, cycling, and walking directions
- Traffic avoidance
- Maneuver announcements
- Text instructions
- Text to speech support via AVSpeechSynthesizer or Amazon Polly
- Automatic rerouting
- Snap to route

## Installation

### [CocoaPods](https://cocoapods.org/)

Add the following lines to your Podfile:

```ruby
pod 'MapboxNavigation.swift', :git => 'https://github.com/mapbox/mapbox-navigation-ios.git', :tag => 'v0.1.0'
pod 'MapboxNavigationUI.swift', :git => 'https://github.com/mapbox/mapbox-navigation-ios.git', :tag => 'v0.1.0'
```

### [Carthage](https://github.com/Carthage/Carthage)

1: Add the following line to your `Cartfile`:
```
github "mapbox/mapbox-navigation-ios"
```
2: Run:
```
carthage update --platform ios
```
3: Drag all frameworks (located in `/Carthage/Build/iOS`) into Embedded Frameworks.

## Usage

```swift
import MapboxDirections
import MapboxNavigation
```

```swift
let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House")

let options = RouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidsTraffic)
options.includesSteps = true

Directions.shared.calculate(options) { (waypoints, routes, error) in
    guard let route = routes?.first else { return }

    let viewController = NavigationUI.routeViewController(for: route)
    self.present(viewController, animated: true, completion: nil)
}
```

See [this guide](https://github.com/mapbox/mapbox-navigation-ios/blob/master/Docs/Storyboards.md) for usage with storyboards.

### UI overrides and listeners

#### Colors

You can override the default colors in the UI.

```swift
// Used for guidance arrow, highlighted text and progress bars.
NavigationUI.shared.tintColor = .red

// Used for guidance arrow
NavigationUI.shared.tintStrokeColor = .blue

// Used for titles and prioritized information
NavigationUI.shared.primaryTextColor = .orange

// Used for subtitles, distances and accessory labels
NavigationUI.shared.secondaryTextColor = .pink

// Used for separators in table views
NavigationUI.shared.lineColor = .yellow
```

#### RouteViewController Delegate Methods

* `routeControllerDidCancelNavigation`: Fired when the user taps `Cancel`. You are responsible for dismissing the UI

## Examples

We provide examples in Swift and Objective-C. Run `carthage update --platform ios` from the root folder and open MapboxNavigation.xcodeproj to try it out.

### Running the example app

1. If running in the simulator, you can simulate the user location by selecting `Debug` -> `Location` -> `City Bicycle Ride`
1. Long press any where on a map. This is where you will be routed to.
1. Press `Start Navigation` to begin
1. Press `Cancel` to end

## Building your own custom navigation UI

Mapbox Navigation gives you all the components you need, should you want to build your own custom turn-by-turn navigation UI:

* [Mapbox Maps SDK](https://www.mapbox.com/ios-sdk/)
* [Mapbox Studio](https://www.mapbox.com/studio/)
  * Design custom maps with live traffic overlays
* [MapboxDirections](https://github.com/mapbox/MapboxDirections.swift)
  * Automotive, cycling, and walking directions
  * Traffic-influenced driving directions
* Mapbox Core Navigation (`MapboxCoreNavigation` module)
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

### Route Controller

`RouteController` is given a route. Internally `RouteController` matches the user's current location to the route while looking at 3 principle pieces:

1. Is the user on or off the route?
1. How far along the step is the user?
1. Does the user need to be alerted about an upcoming maneuver?

The library compares the user from the route and decides upon each one of these parameters and acts accordingly. The developer is told what is happening behind the scenes via `NSNotification`.

### Guidance Notifications

This library relies heavily on `NSNotification`s for letting the developer know when events have occurred.

#### `RouteControllerProgressDidChange`

* Emitted when the user moves along the route. Notification contains 3 keys:
  * `RouteControllerProgressDidChangeNotificationProgressKey` - `RouteProgress` - Current progress along route
  * `RouteControllerProgressDidChangeNotificationLocationKey` - `CLLocation` - Current location
  * `RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey` - `Double` - Given users speed and location, this is the number of seconds left to the end of the step

#### `RouteControllerAlertLevelDidChange`

* Emitted when the alert level changes. This indicates the user should be notified about the upcoming maneuver. See [Alerts](#Alert levels). Notification contains 3 keys:
  * `RouteControllerProgressDidChangeNotificationProgressKey` - `RouteProgress` - Current progress along route
  * `RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey` - `CLLocationDistance` - The users snapped distance to the end of the route.

#### `RouteControllerShouldReroute`

* Emitted when the user is off the route and should be rerouted. Notification contains 1 key:
  * `RouteControllerNotificationShouldRerouteKey` - `CLLocation` - Last location of user

### Alert levels

Alert levels indicate the type of announcement that should be given. The enum types available are:

* `none`
* `depart` - Emitted while departing origin
* `low` - Emitted directly after completing the maneuver
* `medium` - Emitted when the user has [70 seconds](https://github.com/mapbox/mapbox-navigation-ios/blob/19365cdad5f18641579a560dfc7113057b3053ad/MapboxNavigation/Constants.swift#L15) remaining on the route.
* `high` - Emitted when the user has [15 seconds](https://github.com/mapbox/mapbox-navigation-ios/blob/19365cdad5f18641579a560dfc7113057b3053ad/MapboxNavigation/Constants.swift#L16) remaining on the route.
* `arrive` - Emitted when the user arrives at destination

### Rerouting

In the event of a reroute, it's necessary to update the current route with a new route. Once fetched, you can update the current route by:

```swift
navigation.routeProgress = RouteProgress(route: newRoute)
```

## License

Mapbox Navigation SDK for iOS is released under the ISC License. [See LICENSE](https://github.com/mapbox/mapbox-navigation-ios/blob/master/LICENSE) for details.
