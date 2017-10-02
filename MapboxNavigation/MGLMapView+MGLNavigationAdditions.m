#import "MGLMapView+MGLNavigationAdditions.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation MGLMapView (MGLNavigationAdditions)
#pragma clang diagnostic pop

- (CADisplayLink *)displayLink {
    return [self valueForKey:@"_displayLink"];
}

@end
