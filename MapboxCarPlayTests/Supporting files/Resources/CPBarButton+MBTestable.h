#import <Foundation/Foundation.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000
#import <CarPlay/CarPlay.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(12.0))
@interface CPBarButton (MBTestable)

@property (nonatomic, copy, readonly) void (^ _Nullable handler)(CPBarButton *);

@end

NS_ASSUME_NONNULL_END

#endif
