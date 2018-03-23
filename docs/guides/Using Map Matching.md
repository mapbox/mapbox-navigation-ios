# Using Map Matching with the Navigation SDK

In some cases, you may want to have the user stick to a very specific route, one that does not fit into the scope covered by the Mapbox Directions API. For example, a company would like to use their custom truck routing API but allow people to navigate on it with the Mapbox Navigation SDK. In this case, the Mapbox Map Matching API is an appropriate fit.

Map Matching is the art of taking coordinates and aligning them along a road network. In the truck example above, you would hit your own truck routing API, give us the coordinates and then we'd return a Route that can plug into the Navigation SDK.

When using the Map Matching SDK with the Navigation SDK, there are a few rules you must adhere to:

### `navigationViewController(:shouldRerouteFrom:)` to false

```swift
func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
    return false
}
```

If the user were to go off route immediately after starting along their route, the Navigation SDK would fetch a new route via the Mapbox Directions API. This would throw the initial route out that contained the custom truck profile.

### Fetch a new route after rerouting

It is up to you to listen in on reroutes and:

1. Fetch a new route from your server.
1. Make a map matching request against the Mapbox Map Matching appropriate.
1. Update the `RouteProgress` with a the new route (covered below).

### Update the RouteProgress

Once you have a fresh route after rerouting, you need to tell the UI to update according to this new route.

```
yourNavigationViewController.route = route
```

This will cause a waterfall effect, everything downstream should react to the addition of a new route.

### Making the request

Always make sure to use `NavigationMatchOptions` when creating a map matching request. This is subclass of `MatchOptions` which applies a good set of default options for navigation.

It is also import to use `Directions.calculateRoutes(matching:completionHandler:).` when creating the request. This returns a `Route` instead of `Match` which allows us to navigate on it.
