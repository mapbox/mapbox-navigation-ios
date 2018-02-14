#import <Foundation/Foundation.h>

/**
 Posted when `MBRouteController` receives a user location update representing movement along the expected route.
 
 The user info dictionary contains the keys `MBRouteControllerProgressDidChangeNotificationProgressKey`, `MBRouteControllerProgressDidChangeNotificationLocationKey`, and `MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerProgressDidChangeNotification;

/**
 Posted after the user diverges from the expected route, just before `MBRouteController` attempts to calculate a new route.
 
 The user info dictionary contains the key `MBRouteControllerNotificationLocationKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerWillRerouteNotification;

/**
 Posted when `MBRouteController` obtains a new route in response to the user diverging from a previous route.
 
 The user info dictionary contains the keys `MBRouteControllerNotificationLocationKey` and `MBRouteControllerDidFindFasterRouteKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerDidRerouteNotification;

/**
 Posted when `MBRouteController` fails to reroute the user after the user diverges from the expected route.
 
 The user info dictionary contains the key `MBRouteControllerNotificationErrorKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerDidFailToRerouteNotification;

/**
 Posted when `MBRouteController` detects that the user has passed an ideal point for saying an instruction aloud.
 
 The user info dictionary contains the key `MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerDidPassSpokenInstructionPointNotification;

/**
 Posted when something changes in the shared `MBNavigationSettings` object.
 
 The user info dictionary indicates which keys and values changed.
 
 :nodoc:
 */
extern const NSNotificationName MBNavigationSettingsDidChangeNotification;

/**
 Keys in the user info dictionaries of various notifications posted by instances of `MBRouteController`.
 
 :nodoc:
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
