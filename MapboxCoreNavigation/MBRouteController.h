#import <Foundation/Foundation.h>


extern NSString *const MBRouteControllerProgressDidChangeNotificationProgressKey;
extern NSString *const MBRouteControllerProgressDidChangeNotificationLocationKey;
extern NSString *const MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey;

extern NSString *const MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey;
extern NSString *const MBRouteControllerDidPassSpokenInstructionPoint;

extern NSString *const MBRouteControllerNotificationLocationKey;
extern NSString *const MBRouteControllerNotificationRouteKey;
extern NSString *const MBRouteControllerNotificationErrorKey;

extern NSString *const MBRouteControllerNotificationProgressDidChange;
extern NSString *const MBRouteControllerWillReroute;
extern NSString *const MBRouteControllerDidReroute;
extern NSString *const MBRouteControllerDidFailToReroute;
extern NSString *const MBRouteControllerDidFindFasterRouteKey;

extern NSString *const MBNavigationSettingsDidChange;

/**
 Constant representing the domain in which errors created in this library will live under.
 */
extern NSString *const MBErrorDomain;

/**
 Key used for constructing errors when spoken instructions fail.
 */
extern NSString *const MBSpokenInstructionErrorCodeKey;
