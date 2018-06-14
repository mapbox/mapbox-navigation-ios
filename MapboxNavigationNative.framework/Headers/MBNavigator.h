#import <Foundation/Foundation.h>

@class MBFixLocation;
@class MBNavigationStatus;

@interface MBNavigator : NSObject
- (nonnull instancetype)init;
- (nonnull MBNavigationStatus *)setDirectionsForDirections:(nonnull NSString *)directions;
- (nonnull MBNavigationStatus *)onLocationChangedForFixLocation:(nonnull MBFixLocation *)fixLocation;
- (nullable NSNumber *)getBearing;
@end
