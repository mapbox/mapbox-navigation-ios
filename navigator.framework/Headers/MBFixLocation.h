#import <Foundation/Foundation.h>

@interface MBFixLocation : NSObject
- (nonnull instancetype)initWithLat:(float)lat
                                lon:(float)lon
                               time:(nullable NSNumber *)time
                              speed:(nullable NSNumber *)speed
                            bearing:(nullable NSNumber *)bearing
                           altitude:(nullable NSNumber *)altitude
                 accuracyHorizontal:(nullable NSNumber *)accuracyHorizontal
                           provider:(nullable NSString *)provider;

@property (nonatomic, readonly) float lat;
@property (nonatomic, readonly) float lon;
@property (nonatomic, readonly, nullable) NSNumber * time;
@property (nonatomic, readonly, nullable) NSNumber * speed;
@property (nonatomic, readonly, nullable) NSNumber * bearing;
@property (nonatomic, readonly, nullable) NSNumber * altitude;
@property (nonatomic, readonly, nullable) NSNumber * accuracyHorizontal;
@property (nonatomic, readonly, nullable, copy) NSString * provider;
@end
