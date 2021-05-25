#import "CPMapTemplate+MBTestable.h"
#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000

#import <CarPlay/CarPlay.h>

@interface CPMapTemplate (MBTestableInternal)

@end

@implementation CPMapTemplate (MBTestable)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (CPNavigationSession *)startNavigationSessionForTrip:(CPTrip *)trip {
    NSAssert(FALSE, @"Reimplement without Cedar");
    return nil;
}

#pragma clang diagnostic pop

@end

#endif
