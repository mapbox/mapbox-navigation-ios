#import <Mapbox/Mapbox.h>

@interface MGLMapView (MGLNavigationAdditions)

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;

@end
