#import <Foundation/Foundation.h>

/**
 Posted when `RouteController` receives a user location update representing movement along the expected route.
 
 The user info dictionary contains the keys `RouteControllerNotificationUserInfoKey.progressDidChangeNotificationProgressKey`, `RouteControllerNotificationUserInfoKey.progressDidChangeNotificationLocationKey`, and `RouteControllerNotificationUserInfoKey.progressDidChangeNotificationSecondsRemainingOnStepKey`.
 */
extern const NSNotificationName MBRouteControllerProgressDidChangeNotification;

/**
 Posted after the user diverges from the expected route, just before `RouteController` attempts to calculate a new route.
 
 The user info dictionary contains the key `RouteControllerNotificationUserInfoKey.locationKey`.
 */
extern const NSNotificationName MBRouteControllerWillRerouteNotification;

/**
 Posted when `RouteController` obtains a new route in response to the user diverging from a previous route.
 
 The user info dictionary contains the keys `RouteControllerNotificationUserInfoKey.locationKey` and `RouteControllerNotificationUserInfoKey.didFindFasterRouteKey`.
 */
extern const NSNotificationName MBRouteControllerDidRerouteNotification;

/**
 Posted when `RouteController` fails to reroute the user after the user diverges from the expected route.
 
 The user info dictionary contains the key `RouteControllerNotificationUserInfoKey.errorKey`.
 */
extern const NSNotificationName MBRouteControllerDidFailToRerouteNotification;

/**
 Posted when `RouteController` detects that the user has passed an ideal point for saying an instruction aloud.
 
 The user info dictionary contains the key `RouteControllerNotificationUserInfoKey.didPassSpokenInstructionPointRouteProgressKey`.
 */
extern const NSNotificationName MBRouteControllerDidPassSpokenInstructionPointNotification;

/**
 Posted when something changes in the shared `NavigationSettings` object.
 
 The user info dictionary indicates which keys and values changed.
 */
extern const NSNotificationName MBNavigationSettingsDidChangeNotification;

/**
 Keys in the user info dictionaries of various notifications posted by instances
 of `RouteController`.
 */
typedef NSString *MBRouteControllerNotificationUserInfoKey NS_EXTENSIBLE_STRING_ENUM;

/**
 A key in the user info dictionary of a `Notification.Name.MBRouteControllerProgressDidChange` notification. The corresponding value is a `RouteProgress` object representing the current route progress.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerProgressDidChangeNotificationProgressKey;

/**
 A key in the user info dictionary of a `Notification.Name.MBRouteControllerProgressDidChange` notification. The corresponding value is a `CLLocation` object representing the current user location.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerProgressDidChangeNotificationLocationKey;

/**
 A key in the user info dictionary of a `Notification.Name.RouteControllerProgressDidChange` notification. The corresponding value is an `NSNumber` instance containing a double value indicating the number of seconds left on the current step.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey;

/**
 A key in the user info dictionary of a `Notification.Name.RouteControllerDidPassSpokenInstructionPoint` notification. The corresponding value is a `RouteProgress` object representing the current route progress.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey;

/**
 A key in the user info dictionary of a `Notification.Name.RouteControllerWillReroute` notification. The corresponding value is a `CLLocation` object representing the current user location.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerNotificationLocationKey;

/**
 A key in the user info dictionary of a `Notification.Name.RouteControllerDidReroute` notification. The corresponding value is a `Route` object representing the new route.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerNotificationRouteKey;

/**
 A key in the user info dictionary of a `Notification.Name.RouteControllerDidFailToReroute` notification. The corresponding value is an `NSError` object indicating why `RouteController` was unable to calculate a new route.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerNotificationErrorKey;

/**
 A key in the user info dictionary of a `Notification.Name.RouteControllerDidReroute` notification. The corresponding value is an `NSNumber` instance containing a Boolean value indicating whether `RouteController` opportunistically rerouted the user onto a faster route.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerDidFindFasterRouteKey;

/**
 Constant representing the domain in which errors created in this library will live under.
 */
extern NSString *const MBErrorDomain;

/**
 Key used for constructing errors when spoken instructions fail.
 */
extern NSString *const MBSpokenInstructionErrorCodeKey;
