# Simulating Routes

## Waring

_This guide only applies to those *not using the drop in UI*. If you are creating your own navigation UI and would like to simulate a route, follow this guide_

### Why?

By default, with Xcode there are a few ways to simulate locations:

1. In the Simulator.app, you can select `City Bicycle` or `Freeway Drive`

![](img/simulator-location.png)

2. Provide a GPX file with a series of latitudes and longtiudes.

However, there are issues with both of these. One is tied down to a specific location while the other does not allow you to controll the heading or course.

### How

To simulate a route, we are overriding the location manager's [`locationManager(_:didUpdateLocations:)`](https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423615-locationmanager?language=swift) from a series of locations that are coming from a provided route. To do this, we need to expose the location manager on MGLMapView since it is private.

```swift
let simulator = SimulatedLocationManager(route: route)
let routeController = RouteController(along: userRoute!, directions: directions, locationManager: simulator)
```
