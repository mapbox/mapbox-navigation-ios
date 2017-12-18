#import "MBRouteController.h"


NSString *const MBRouteControllerProgressDidChangeNotificationProgressKey               = @"progress";
NSString *const MBRouteControllerProgressDidChangeNotificationLocationKey               = @"location";
NSString *const MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = @"seconds";

NSString *const MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey          = @"progress";

NSString *const MBRouteControllerNotificationLocationKey    = @"location";
NSString *const MBRouteControllerNotificationRouteKey       = @"route";
NSString *const MBRouteControllerNotificationErrorKey       = @"error";

NSString *const MBRouteControllerNotificationProgressDidChange  = @"RouteControllerProgressDidChange";
NSString *const MBRouteControllerDidPassSpokenInstructionPoint  = @"RouteControllerDidPassSpokenInstructionPoint";
NSString *const MBRouteControllerWillReroute                    = @"RouteControllerWillReroute";
NSString *const MBRouteControllerDidReroute                     = @"RouteControllerDidReroute";
NSString *const MBRouteControllerDidFailToReroute               = @"RouteControllerDidFailToReroute";
NSString *const MBRouteControllerDidFindFasterRouteKey          = @"RouteControllerDidFindFasterRoute";
NSString *const MBErrorDomain = @"ErrorDomain";
NSString *const MBSpokenInstructionErrorCodeKey = @"MBSpokenInstructionErrorCode";

NSString *const MBNavigationSettingsDidChange = @"MBNavigationSettingsDidChange";
