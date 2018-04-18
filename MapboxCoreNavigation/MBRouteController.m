#import "MBRouteController.h"

const NSNotificationName MBRouteControllerProgressDidChangeNotification             = @"RouteControllerProgressDidChange";
const NSNotificationName MBRouteControllerDidPassSpokenInstructionPointNotification = @"RouteControllerDidPassSpokenInstructionPoint";
const NSNotificationName MBRouteControllerWillRerouteNotification                   = @"RouteControllerWillReroute";
const NSNotificationName MBRouteControllerDidRerouteNotification                    = @"RouteControllerDidReroute";
const NSNotificationName MBRouteControllerDidFailToRerouteNotification              = @"RouteControllerDidFailToReroute";

const MBRouteControllerNotificationUserInfoKey MBRouteControllerRouteProgressKey              = @"progress";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerLocationKey                   = @"location";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerRawLocationKey                = @"rawLocation";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerRoutingErrorKey               = @"error";
const MBRouteControllerNotificationUserInfoKey MBRouteControllerIsProactiveKey                = @"RouteControllerDidFindFasterRoute";

NSString *const MBErrorDomain = @"ErrorDomain";
