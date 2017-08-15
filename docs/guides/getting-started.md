# Getting started

_Note: the [example app](https://github.com/mapbox/mapbox-navigation-ios/blob/master/Examples/Swift/ViewController.swift) is also a great resource for viewing how to get started. It also has a few more advanced examples._

**Before getting started, make sure you have installed the Navigation SDK, if not [follow these instructions](./installation).**

There are three basic steps most developers will follow.

1. Given two points, fetch a route
1. Pass this route through to the `NavigationViewController`
1. Present the `NavigationViewController` and let the user navigate to their destination.

Here is a very barebones example of how to present the navigation view:

1. Open ViewController.swift and import MapboxNavigation by adding `import MapboxNavigation` to the top.
1. Open your projects storyboard.
1. Add a new UIView, and change it's class to a `MGLMapView`.
![](https://cldup.com/8VD7AUI_EZ.png)
1. Add an IBOutlet to ViewController.swift
1. Add a long press gesture recognizer and create an IBAction for it.
![](https://cldup.com/pPMohaYK0X.png)
1. Add `mapView.userTrackingMode = .follow` to your `viewDidLoad` function.
1. In the long press handler, add the following code:

```swift
@IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
    guard sender.state == .began else {
        return
    }

    // Convert the location of the long press to coordinates
    let endpoint = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)

    let options = RouteOptions(coordinates: [
        mapView.userLocation!.coordinate,
        endpoint,
        ])

    // Necessary options
    options.includesSteps = true
    options.routeShapeResolution = .full
    options.profileIdentifier = .automobileAvoidingTraffic
    options.attributeOptions = [.congestionLevel]

    // Fetch a route
    _ = Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
        guard let strongSelf = self else { return }
        guard error == nil else { return }

        guard let route = routes?.first else { return }

        // Create the `NavigationViewController` for the route
        let navigationViewController = NavigationViewController(for: route)

        // Present navigation
        strongSelf.present(navigationViewController, animated: true, completion: nil)
    }
}
```
1. Use the provided simulates to test a route. Debug -> Location -> City Bicycle
![](https://cldup.com/HO8gnK2iUv.png)
