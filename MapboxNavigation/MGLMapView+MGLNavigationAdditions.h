#import <Mapbox/Mapbox.h>

@interface MGLMapView (MGLNavigationAdditions) <CLLocationManagerDelegate>

- (void)mapViewDidFinishRenderingFrameFullyRendered:(BOOL)fullyRendered;

@end
