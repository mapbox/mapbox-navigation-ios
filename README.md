# MapboxNavigation

MapboxNavigation consists of two libraries. MapboxNavigation.swift which contains the logic needed for turn-by-turn navigation and MapboxNavigationUI.swift that provides all UI elements needed for a great navigation experience.

[📱&nbsp;![iOS Build Status](https://www.bitrise.io/app/6fc45a7e2817b859.svg?token=XTgNMVxObhd8w8EmsAgJ1Q)](https://www.bitrise.io/app/2f82077d3f083479)
&nbsp;&nbsp;&nbsp;
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

| MapboxNavigation.swift | MapboxNavigationUI.swift |
| :---: | :---: |
| ![](https://cloud.githubusercontent.com/assets/764476/23326707/712a7790-fab5-11e6-9419-2aa5bd2f2c7d.png) | ![](https://cloud.githubusercontent.com/assets/764476/23636459/567771d2-028a-11e7-95cf-a8832792c67a.png) |

## Examples

We provide examples in Swift and Objective-C. Run `carthage update --platform ios` from the root folder and open MapboxNavigation.xcodeproj to try it out.

### Running the example app

1. If running in the simulator, you can simulate the user location by selecting `Debug` -> `Location` -> `City Bicycle Ride`
1. Long press any where on a map. This is where you will be routed to.
1. Press `Start Navigation` to begin
1. Press `Cancel` to end

## MapboxNavigation.swift

### Installation options

#### [CocoaPods](https://cocoapods.org/)

Add the following lines to your Podfile:

```ruby
# Required
pod 'MapboxNavigation.swift', :git => 'https://github.com/mapbox/MapboxNavigation.swift.git', :commit => 'c5a637a201a3043c24e52f3e2c50a1657a8ffced'
pod 'MapboxNavigationUI.swift', :git => 'https://github.com/mapbox/MapboxNavigation.swift.git', :commit => 'c5a637a201a3043c24e52f3e2c50a1657a8ffced'
pod 'OSRMTextInstructions', :git => 'git@github.com:Project-OSRM/osrm-text-instructions.swift.git', :commit => 'bdd962bf5593f951bbbbd26435f732a829dacda7'

# Optional but, you will most likely use:
pod 'Mapbox-iOS-SDK', '~> 3.4'
```

#### [Carthage](https://github.com/carthage/carthage)

Add the following line to your Cartfile:

```ruby
github "mapbox/MapboxNavigation.swift"
```

### Gist of how this works

`RouteController` is given a route. Internally, MapboxNavigation.swift is comparing the route to the users location and looking at 3 principle pieces:

1. Is the user on or off the route?
1. How far along the step is the user?
1. Does the user need to be alerted about an upcoming maneuver?

The library compares the user from the route and decides upon each one of these parameters and acts accordingly. The developer is told what is happening behind the scenes via `NSNotification`.

### Notifications

This library relies heavily on the class `NSNotification` for letting the developer know when events have occurred.

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
* `medium` - Emitted when the user has [70 seconds](https://github.com/mapbox/MapboxNavigation.swift/blob/19365cdad5f18641579a560dfc7113057b3053ad/MapboxNavigation/Constants.swift#L15) remaining on the route.
* `high` - Emitted when the user has [15 seconds](https://github.com/mapbox/MapboxNavigation.swift/blob/19365cdad5f18641579a560dfc7113057b3053ad/MapboxNavigation/Constants.swift#L16) remaining on the route.
* `arrive` - Emitted when the user arrives at destination

### Rerouting

In the event of a reroute, it's necessary to update the current route with a new route. Once fetched, you can update the current route by:

```swift
navigation.routeProgress = RouteProgress(route: newRoute)
```

----

## MapboxNavigationUI.swift

[![](https://www.bitrise.io/app/6fc45a7e2817b859.svg?token=XTgNMVxObhd8w8EmsAgJ1Q)](https://www.bitrise.io/app/6fc45a7e2817b859#/builds)

MapboxNavigationUI.swift makes it easy for developers to add turn-by-turn navigation to their iOS application. You still have access to all emitted notifications identified above however, MapboxNavigationUI takes care of all the alerts, rerouting, etc.

|![](https://cloud.githubusercontent.com/assets/764476/23636459/567771d2-028a-11e7-95cf-a8832792c67a.png) | ![](https://cloud.githubusercontent.com/assets/764476/23671279/883c63ae-031f-11e7-8396-b404d18881e1.png) |
| --- | --- |

### Installation options

#### [CocoaPods](https://cocoapods.org/)

You'll need to install three pods, `MapboxNavigationUI.swift`, `MapboxNavigation.swift`  and `MapboxDirections.swift`

Add the following lines to your Podfile:

```ruby
pod 'MapboxDirections.swift', '~> 0.8'
pod 'MapboxNavigation.swift', :git => 'https://github.com/mapbox/MapboxNavigation.swift.git', :tag => 'v0.0.4'
pod 'MapboxNavigationUI.swift', :git => 'https://github.com/mapbox/MapboxNavigation.swift.git', :commit => 'a368a73a7575b296886ae53b7642216c167ca8e2'
```

#### [Carthage](https://github.com/Carthage/Carthage)

1: Add the following line to your `Cartfile`:
```
github "mapbox/MapboxNavigation.swift" "a368a73a7575b296886ae53b7642216c167ca8e2"
```
2: Run:
```
carthage update --platform ios
```
3: Drag all frameworks (located in `/Carthage/Build/iOS`) into Embedded Frameworks.

### Set up navigation UI in code

```swift
let viewController = NavigationUI.routeViewController(for: route, directions: directions)
present(viewController, animated: true, completion: nil)
```

- `route` the initial route you want to navigate.
- `directions` an optional [Direction](https://github.com/mapbox/MapboxDirections.swift) instance needed for re-routing when the user goes off route. If no directions instance is provided, a default one will be used.

### Set up navigation UI in a storyboard

- Open the object library and drag in a `Storyboard Reference`.
- Pick `Navigation` from the dropdown and set bundle to `com.mapbox.MapboxNavigationUI`.
- Set up a segue to the storyboard reference like you would to any other UIViewController.

<img src="https://cloud.githubusercontent.com/assets/764476/23622518/e3cc8a86-0253-11e7-80ab-7d34302a5fe5.png" width=340>

You also need to pass a route and optionally a directions instance to the `RouteViewController`. To do that, override your UIViewController's `prepare(for:sender:)`:

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier ?? "" {
        case "MyNavigationSegue":
            if let controller = segue.destination as? RouteViewController {
                controller.route = route
                controller.directions = directions
            }
        default:
            break
    }
}
```

### UI overrides and listeners

#### Colors

You can override the default colors in the UI.

```swift
NavigationUI.shared.tintColor = .red
NavigationUI.shared.tintStrokeColor = .blue
NavigationUI.shared.primaryTextColor = .orange
NavigationUI.shared.secondaryTextColor = .pink
```

#### `routeControllerDidCancelNavigation`

Fired when the user taps `Cancel`. Note, this delegate method should also dismiss the UI.

```swift
func routeViewControllerDidCancelNavigation(_: RouteViewController) {
    // Do stuff now

    // Also make sure to dismiss the UI!
    routeViewController.dismiss(animated: true, completion: nil)
}
```
