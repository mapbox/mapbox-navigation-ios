#import <Foundation/Foundation.h>
@import MapboxMobileEvents;

NS_ASSUME_NONNULL_BEGIN

@interface MMEEventsManager (Spy)

- (instancetype)initShared;
+ (instancetype)testableInstance;

@end

NS_ASSUME_NONNULL_END
