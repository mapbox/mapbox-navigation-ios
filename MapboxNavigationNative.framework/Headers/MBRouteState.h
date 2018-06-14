#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MBRouteState)
{
    MBRouteStateInvalid,
    MBRouteStateInitialized,
    MBRouteStateTracking,
    MBRouteStateComplete,
    MBRouteStateOffRoute
};
