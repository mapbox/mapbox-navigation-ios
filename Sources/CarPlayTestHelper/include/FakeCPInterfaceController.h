#import <Foundation/Foundation.h>
@import CarPlay;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(12.0))
@interface FakeCPInterfaceController : CPInterfaceController
/// A simple stub which allows for instantiation of a CPInterfaceController for testing.
/// CPInterfaceController cannot be instantiated directly. Properties which don't work in headless testing will need to
/// be overridden with test-specific mock functionality provided.
- (instancetype)initWithContext:(NSString *)context;
@end

NS_ASSUME_NONNULL_END
