#import <Mapbox/Mapbox.h>

@interface MGLMapView (MGLNavigationAdditions) <CLLocationManagerDelegate>

// FIXME: This will be removed once https://github.com/mapbox/mapbox-gl-native/issues/6867 is implemented
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations;

// FIXME: This will be removed once https://github.com/mapbox/mapbox-navigation-ios/issues/352 is implemented.
- (void)validateLocationServices;

@property (nonatomic, readonly) CLLocationManager *locationManager;

@end
