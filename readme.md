# MapboxNavigation.swift

MapboxNavigation.swift provides an API to add turn by turn navigation to your app. The basic workflow of how it fits into your app:

1. Provide `RouteController` with a [route](https://github.com/mapbox/MapboxDirections.swift)
1. Start the `RouteController` with `resume()` when the user should enter guidance mode
1. MapboxNavigation.swift will then emit `NSNotification` when:
 * The use makes progress along the route
 * The user should be alerted about an upcoming maneuver
 * The user should be rerouted
1. Depending on what is emitted, your app should react accordingly

A simple implementation can be viewed in the [Example app](./ViewController.swift).
