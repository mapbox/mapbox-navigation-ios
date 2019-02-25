#import "CPMapTemplate+MBTestable.h"
#import <Cedar/Cedar.h>
#import <objc/runtime.h>

using namespace Cedar::Doubles;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000

#import <CarPlay/CarPlay.h>

@interface CPMapTemplate (MBTestableInternal)

@end


@implementation CPMapTemplate (MBTestable)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (CPNavigationSession *)startNavigationSessionForTrip:(CPTrip *)trip {
    return nice_fake_for(CPNavigationSession.class);
}

#pragma clang diagnostic pop

@end

#endif
