#import "MGLMapView+MGLNavigationAdditions.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
// Supressing compiler warning until https://github.com/mapbox/mapbox-gl-native/issues/6867 is implemented
@implementation MGLMapView (MGLNavigationAdditions)
#pragma clang diagnostic pop

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                edgePadding:(UIEdgeInsets)edgePadding
                  zoomLevel:(double)zoomLevel
                  direction:(CLLocationDirection)direction
{
    [self _setCenterCoordinate:centerCoordinate
                   edgePadding:edgePadding
                     zoomLevel:zoomLevel
                     direction:direction
                      duration:0
       animationTimingFunction:nil
             completionHandler:nil];
}

@end
