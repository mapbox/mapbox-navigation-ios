# MapboxNavigation.swift

[![](https://www.bitrise.io/app/6fc45a7e2817b859.svg?token=XTgNMVxObhd8w8EmsAgJ1Q)](https://www.bitrise.io/app/6fc45a7e2817b859#/builds)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

![](https://cldup.com/Th0sa6Vnvf.gif)
> *Example app guiding the user along a route*

MapboxNavigation.swift provides an API to add turn by turn navigation to your app. The basic workflow of how it fits into your app:

1. Provide `RouteController` with a [route](https://github.com/mapbox/MapboxDirections.swift)
1. Start the `RouteController` with `resume()` when the user should enter guidance mode
1. MapboxNavigation.swift will then emit `NSNotification` when:
 * The use makes progress along the route
 * The user should be alerted about an upcoming maneuver
 * The user should be rerouted
1. Depending on what is emitted, your app should react accordingly

A simple implementation can be viewed in the example app — available in [Objective-C](./Example/Objective-C/ViewController.m) or [Swift](./Example/Swift/ViewController.swift).

## Installation options

#### [CocoaPods](https://cocoapods.org/)

You'll need to install two pods, `MapboxNavigation.swift` and `MapboxDirections.swift`

Add the following lines to your Podfile:

```ruby
pod 'MapboxDirections.swift', :git => 'https://github.com/mapbox/MapboxDirections.swift.git', :commit => 'ceaf58b780fc17ea44a9150041b602d017c1e567'
pod 'MapboxNavigation.swift', :git => 'https://github.com/mapbox/MapboxNavigation.swift.git', :tag => 'v0.0.4'
```

#### [Carthage](https://github.com/carthage/carthage)

Add the following line to your Cartfile:

```ruby
github "mapbox/MapboxNavigation.swift"
```

## Gist of how this works

`RouteController` is given a route. Internally, MapboxNavigation.swift is comparing the route to the users location and looking at 3 principle pieces:

1. Is the user on or off the route?
1. How far along the step is the user?
1. Does the user need to be alerted about an upcoming maneuver?

The library compares the user from the route and decides upon each one of these parameters and acts accordingly. The developer is told what is happening behind the scenes via `NSNotification`.

## Notifications

This library relies heavily on the class `NSNotification` for letting the developer know when events have occurred.

### `RouteControllerProgressDidChange`

* Emitted when the user moves along the route. Notification contains 3 keys:
  * `RouteControllerProgressDidChangeNotificationProgressKey` - `RouteProgress` - Current progress along route
  * `RouteControllerProgressDidChangeNotificationLocationKey` - `CLLocation` - Current location
  * `RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey` - `Double` - Given users speed and location, this is the number of seconds left to the end of the step

### `RouteControllerAlertLevelDidChange`

* Emitted when the alert level changes. This indicates the user should be notified about the upcoming maneuver. See [Alerts](#Alert levels). Notification contains 3 keys:
  * `RouteControllerProgressDidChangeNotificationProgressKey` - `RouteProgress` - Current progress along route
  * `RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey` - `CLLocationDistance` - The users snapped distance to the end of the route.

### `RouteControllerShouldReroute`

* Emitted when the user is off the route and should be rerouted. Notification contains 1 key:
  * `RouteControllerNotificationShouldRerouteKey` - `CLLocation` - Last location of user

## Alert levels

Alert levels indicate the type of announcement that should be given. The enum types available are:

* `none`
* `depart` - Emitted while departing origin
* `low` - Emitted directly after completing the maneuver
* `medium` - Emitted when the user has [70 seconds](https://github.com/mapbox/MapboxNavigation.swift/blob/19365cdad5f18641579a560dfc7113057b3053ad/MapboxNavigation/Constants.swift#L15) remaining on the route.
* `high` - Emitted when the user has [15 seconds](https://github.com/mapbox/MapboxNavigation.swift/blob/19365cdad5f18641579a560dfc7113057b3053ad/MapboxNavigation/Constants.swift#L16) remaining on the route.
* `arrive` - Emitted when the user arrives at destination

## Rerouting

In the event of a reroute, it's necessary to update the current route with a new route. Once fetched, you can update the current route by:

```swift
navigation.routeProgress = RouteProgress(route: newRoute)
```

## Examples

We provide examples in Swift and Objective-C. Run `pod install` from the Example folder and open `Example.xcworkspace` to try it out.

## Running the example app

1. If running in the simulator, you can simulate the user location by selecting `Debug` -> `Location` -> `City Bicycle Ride`
1. Long press any where on a map. This is where you will be routed to.
1. Press `Start Navigation` to begin
1. Press `Stop Navigation` to end
