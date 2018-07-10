#import <Mapbox/Mapbox.h>

@interface MGLMapView (MGLNavigationAdditions)

- (void)mapViewDidFinishRenderingFrameFullyRendered:(BOOL)fullyRendered;

@property (nonatomic, readonly) CADisplayLink  * _Nullable displayLink;

@end
