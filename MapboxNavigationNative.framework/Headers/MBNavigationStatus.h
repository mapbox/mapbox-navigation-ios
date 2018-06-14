#import <Foundation/Foundation.h>
#import "MBRouteState.h"

@class MBBanner;
@class MBVoiceInstruction;

@interface MBNavigationStatus : NSObject
- (nonnull instancetype)initWithRouteState:(MBRouteState)routeState
                                       lat:(float)lat
                                       lon:(float)lon
                                   bearing:(float)bearing
                                routeIndex:(uint32_t)routeIndex
                                  legIndex:(uint32_t)legIndex
                      remainingLegDistance:(float)remainingLegDistance
                      remainingLegDuration:(uint32_t)remainingLegDuration
                                 stepIndex:(uint32_t)stepIndex
                     remainingStepDistance:(float)remainingStepDistance
                     remainingStepDuration:(uint32_t)remainingStepDuration
                          voiceInstruction:(nullable MBVoiceInstruction *)voiceInstruction
                         bannerInstruction:(nullable MBBanner *)bannerInstruction
                              stateMessage:(nonnull NSString *)stateMessage;

@property (nonatomic, readonly) MBRouteState routeState;
@property (nonatomic, readonly) float lat;
@property (nonatomic, readonly) float lon;
@property (nonatomic, readonly) float bearing;
@property (nonatomic, readonly) uint32_t routeIndex;
@property (nonatomic, readonly) uint32_t legIndex;
@property (nonatomic, readonly) float remainingLegDistance;
@property (nonatomic, readonly) uint32_t remainingLegDuration;
@property (nonatomic, readonly) uint32_t stepIndex;
@property (nonatomic, readonly) float remainingStepDistance;
@property (nonatomic, readonly) uint32_t remainingStepDuration;
@property (nonatomic, readonly, nullable) MBVoiceInstruction * voiceInstruction;
@property (nonatomic, readonly, nullable) MBBanner * bannerInstruction;
@property (nonatomic, readonly, nonnull, copy) NSString * stateMessage;
@end
