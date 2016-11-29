# MapboxNavigation.swift

MapboxNavigation.swift provides an API to add turn by turn navigation to your app. The basic workflow of how it fits into your app:

1. Provide `RouteController` with a [route](https://github.com/mapbox/MapboxDirections.swift)
1. Start the `RouteController` with `resume()` when the user should enter guidance mode
1. MapboxNavigation.swift will then emit `NSNotification` when:
 * The use makes progress along the route
 * The user should be alerted about an upcoming maneuver
 * The user should be rerouted
1. Depending on what is emitted, your app should react accordingly

A simple implementation can be viewed in the [Example app](./Example/ViewController.swift).


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
  * `RouteControllerProgressDidChangeNotificationIsFirstAlertForStepKey` - `Bool` - Whether or not the alert level has already changed once on this step.

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
