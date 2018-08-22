#import <Mapbox/Mapbox.h>

@interface MGLMapView (MGLNavigationAdditions)

- (void)mapViewDidFinishRenderingFrameFullyRendered:(BOOL)fullyRendered;

@end
