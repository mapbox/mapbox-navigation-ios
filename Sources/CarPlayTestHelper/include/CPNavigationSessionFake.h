#import <Foundation/Foundation.h>
@import CarPlay;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(12.0))
@interface CPNavigationSessionFake : CPNavigationSession
- (instancetype)initWithManeuvers:(NSArray<CPManeuver *> *)maneuvers;
@end

NS_ASSUME_NONNULL_END
