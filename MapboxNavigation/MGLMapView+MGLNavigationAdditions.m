#import "MGLMapView+MGLNavigationAdditions.h"

@implementation MGLMapView (MGLNavigationAdditions)

- (void)mapViewDidFinishRenderingFrameFullyRendered:(BOOL)fullyRendered { }

- (CADisplayLink *)displayLink {
    return [self valueForKey:@"_displayLink"];
}

@end
