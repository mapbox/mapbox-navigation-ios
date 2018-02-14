#import "MBRouteController.h"

const NSNotificationName MBRouteControllerProgressDidChangeNotification  = @"RouteControllerProgressDidChange";
const NSNotificationName MBRouteControllerDidPassSpokenInstructionPointNotification  = @"RouteControllerDidPassSpokenInstructionPoint";
const NSNotificationName MBRouteControllerWillRerouteNotification                    = @"RouteControllerWillReroute";
const NSNotificationName MBRouteControllerDidRerouteNotification                     = @"RouteControllerDidReroute";
const NSNotificationName MBRouteControllerDidFailToRerouteNotification               = @"RouteControllerDidFailToReroute";

const MBRouteControllerNotificationUserInfoKey MBRouteControllerProgressDidChangeNotificationProgressKey               = @"progress";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerProgressDidChangeNotificationLocationKey               = @"location";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = @"seconds";

const MBRouteControllerNotificationUserInfoKey MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey          = @"progress";

const MBRouteControllerNotificationUserInfoKey MBRouteControllerNotificationLocationKey    = @"location";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerNotificationRouteKey       = @"route";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerNotificationErrorKey       = @"error";

const MBRouteControllerNotificationUserInfoKey MBRouteControllerDidFindFasterRouteKey          = @"RouteControllerDidFindFasterRoute";

NSString *const MBErrorDomain = @"ErrorDomain";
NSString *const MBSpokenInstructionErrorCodeKey = @"MBSpokenInstructionErrorCode";

NSString *const MBNavigationSettingsDidChangeNotification = @"MBNavigationSettingsDidChange";
