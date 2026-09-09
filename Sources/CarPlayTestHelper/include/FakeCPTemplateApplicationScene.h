#import <Foundation/Foundation.h>
@import CarPlay;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface FakeCPTemplateApplicationScene : CPTemplateApplicationScene
/// A simple stub which allows for instantiation of a CPTemplateApplicationScene for testing.
- (instancetype)initWithContext:(NSString *)context;
@end

NS_ASSUME_NONNULL_END
