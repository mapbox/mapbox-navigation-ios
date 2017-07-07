#import "MBRouteController.h"


NSString *const MBRouteControllerProgressDidChangeNotificationProgressKey               = @"progress";
NSString *const MBRouteControllerProgressDidChangeNotificationLocationKey               = @"location";
NSString *const MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = @"seconds";

NSString *const MBRouteControllerAlertLevelDidChangeNotificationRouteProgressKey            = @"progress";
NSString *const MBRouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey  = @"distance";

NSString *const MBRouteControllerNotificationLocationKey    = @"location";
NSString *const MBRouteControllerNotificationRouteKey       = @"route";
NSString *const MBRouteControllerNotificationErrorKey       = @"error";

NSString *const MBRouteControllerNotificationProgressDidChange  = @"RouteControllerProgressDidChange";
NSString *const MBRouteControllerAlertLevelDidChange            = @"RouteControllerAlertLevelDidChange";
NSString *const MBRouteControllerWillReroute                    = @"RouteControllerWillReroute";
NSString *const MBRouteControllerDidReroute                     = @"RouteControllerDidReroute";
NSString *const MBRouteControllerDidFailToReroute               = @"RouteControllerDidFailToReroute";
