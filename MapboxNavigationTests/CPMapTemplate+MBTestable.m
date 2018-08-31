#import "CPMapTemplate+MBTestable.h"
#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000

#import <CarPlay/CarPlay.h>

@interface CPMapTemplate (MBTestableInternal)

@end


//static char *CurrentTripKey;

@implementation CPMapTemplate (MBTestable)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (CPNavigationSession *)startNavigationSessionForTrip:(CPTrip *)trip {
    return nil;
}

#pragma clang diagnostic pop

@end

#endif
