#import "MGLMapView+MGLNavigationAdditions.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
// Supressing compiler warning until https://github.com/mapbox/mapbox-gl-native/issues/6867 is implemented
@implementation MGLMapView (MGLNavigationAdditions)
#pragma clang diagnostic pop

@dynamic locationManager;

@end
