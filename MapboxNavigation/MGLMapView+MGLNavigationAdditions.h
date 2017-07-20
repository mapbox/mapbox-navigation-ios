#import <Mapbox/Mapbox.h>

@interface MGLMapView (MGLNavigationAdditions) <CLLocationManagerDelegate>

- (void)_setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate edgePadding:(UIEdgeInsets)insets zoomLevel:(double)zoomLevel direction:(CLLocationDirection)direction duration:(NSTimeInterval)duration animationTimingFunction:(nullable CAMediaTimingFunction *)function completionHandler:(nullable void (^)(void))completion;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                edgePadding:(UIEdgeInsets)edgePadding
                  zoomLevel:(double)zoomLevel
                  direction:(CLLocationDirection)direction;

@end
