#import "CPMapTemplate+MBTestable.h"
#import "CPNavigationSessionFake.h"
#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000

#import <CarPlay/CarPlay.h>

@implementation CPMapTemplate (MBTestable)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (CPNavigationSession *)startNavigationSessionForTrip:(CPTrip *)trip {
    return (id)[[CPNavigationSessionFake alloc] initWithManeuvers:@[]];
}

#pragma clang diagnostic pop

@end

#endif
