#import "MBXEventsService+Spy.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation MBXEventsService (Spy)
#pragma clang diagnostic pop

+ (instancetype)testableInstance {
    return [[super alloc] initShared];
}

@end
