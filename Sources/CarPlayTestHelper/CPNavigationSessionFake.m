#import "CPNavigationSessionFake.h"
@import CarPlay;

@interface CPNavigationSessionFake()
@property (nonatomic, strong) NSMutableArray<CPManeuver *> *fakeManeuvers;
@end

@implementation CPNavigationSessionFake
- (instancetype)initWithManeuvers:(NSArray<CPManeuver *> *)maneuvers {
    /// This is only for tests, so we don't care about leaks.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    self = [super performSelector:NSSelectorFromString(@"init")];
#pragma clang diagnostic pop
    if (self) {
        _fakeManeuvers = [maneuvers mutableCopy];
    }
    return self;
}

- (NSArray<CPManeuver *> *)upcomingManeuvers {
    return self.fakeManeuvers;
}

- (void)setUpcomingManeuvers:(NSArray<CPManeuver *> *)upcomingManeuvers {

}
@end
