# Simulating Routes

## Waring

_This guide only applies to those *not using the drop in UI*. If you are creating your own navigation UI and would like to simulate a route, follow this guide_

### Why?

By default, with Xcode there are a few ways to simulate locations:

1. In the Simulator.app, you can select `City Bicycle` or `Freeway Drive`

![](https://user-images.githubusercontent.com/1058624/40988613-63b3254e-68a0-11e8-9f96-e8556dbb7478.png)

2. Provide a GPX file with a series of latitudes and longtiudes.

However, there are issues with both of these. One is tied down to a specific location while the other does not allow you to controll the heading or course.

### How

To simulate a route, we are overriding the location manager's [`locationManager(_:didUpdateLocations:)`](https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423615-locationmanager?language=swift) from a series of locations that are coming from a provided route. To do this, we need to expose the location manager on MGLMapView since it is private.

### Steps

1. Add these two files to your project:

`MGLMapView+CustomAdditions.h`:

```objc
#import <Mapbox/Mapbox.h>

@interface MGLMapView (CustomAdditions) <CLLocationManagerDelegate>

// FIXME: This will be removed once https://github.com/mapbox/mapbox-gl-native/issues/6867 is implemented
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations;

@property (nonatomic, readonly) CLLocationManager *locationManager;

@end
```

`MGLMapView+CustomAdditions.m`: 
```objc
#import "MGLMapView+CustomAdditions.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
// Supressing compiler warning until https://github.com/mapbox/mapbox-gl-native/issues/6867 is implemented
@implementation MGLMapView (CustomAdditions)
#pragma clang diagnostic pop

@dynamic locationManager;

@end
```

2. Accept popup about `Create Bridging Header`

![](https://user-images.githubusercontent.com/1058624/40989148-cc580d48-68a1-11e8-85ed-5d1e76992ed8.png)

3. Confirm in `Build Settings` that `Objective-C Bridging Header` has the correct path to the bridging header file just added.

![](https://user-images.githubusercontent.com/1058624/40989272-1f440c3c-68a2-11e8-9a4d-f00cdf752187.png)

4. Provide a route to the SimulatedLocationManager

```swift
let simulator = SimulatedLocationManager(route: route)
let routeController = RouteController(along: userRoute!, directions: directions, locationManager: simulator)
```