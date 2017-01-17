#import "MBRouteController.h"


NSString *const MBRouteControllerProgressDidChangeNotificationProgressKey               = @"progress";
NSString *const MBRouteControllerProgressDidChangeNotificationLocationKey               = @"location";
NSString *const MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = @"seconds";
NSString *const MBRouteControllerProgressDidChangeNotificationIsFirstAlertForStepKey    = @"first";

NSString *const MBRouteControllerAlertLevelDidChangeNotificationRouteProgressKey            = @"progress";
NSString *const MBRouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey  = @"distance";

NSString *const MBRouteControllerNotificationShouldRerouteKey   = @"reroute";

NSString *const MBRouteControllerNotificationProgressDidChange  = @"RouteControllerProgressDidChange";
NSString *const MBRouteControllerAlertLevelDidChange            = @"RouteControllerAlertLevelDidChange";
NSString *const MBRouteControllerShouldReroute                  = @"RouteControllerShouldReroute";
