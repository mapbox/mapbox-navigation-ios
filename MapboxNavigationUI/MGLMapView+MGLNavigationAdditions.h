#import <Mapbox/Mapbox.h>

@interface MGLMapView (MGLNavigationAdditions) <CLLocationManagerDelegate>

// FIXME: This will be removed once https://github.com/mapbox/mapbox-gl-native/issues/6867 is implemented
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;

@end
