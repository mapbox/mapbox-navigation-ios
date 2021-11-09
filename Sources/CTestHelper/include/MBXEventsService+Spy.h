#import <Foundation/Foundation.h>
@import MapboxCommon_Private;

NS_ASSUME_NONNULL_BEGIN

@interface MBXEventsService (Spy)

- (instancetype)initShared;
+ (instancetype)testableInstance;

@end

NS_ASSUME_NONNULL_END
