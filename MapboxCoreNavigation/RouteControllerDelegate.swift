import Foundation
import CoreLocation
import MapboxDirections


/**
 The `RouteControllerDelegate` protocol provides methods for responding to significant events during the user’s traversal of a route monitored by a `RouteController`.
 */
@objc(MBRouteControllerDelegate)
public protocol RouteControllerDelegate: class {
    /**
     Returns whether the route controller should be allowed to calculate a new route.
     
     If implemented, this method is called as soon as the route controller detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `routeController(_:willRerouteFrom:)` will be called immediately afterwards.
     
     - parameter routeController: The route controller that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the route controller to calculate a new route; false to keep tracking the current route.
     */
    @objc(routeController:shouldRerouteFromLocation:)
    optional func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool
    
    /**
     Called immediately before the route controller calculates a new route.
     
     This method is called after `routeController(_:shouldRerouteFrom:)` is called, simultaneously with the `RouteControllerWillReroute` notification being posted, and before `routeController(_:didRerouteAlong:)` is called.
     
     - parameter routeController: The route controller that will calculate a new route.
     - parameter location: The user’s current location.
     */
    @objc(routeController:willRerouteFromLocation:)
    optional func routeController(_ routeController: RouteController, willRerouteFrom location: CLLocation)
    
    /**
     Called when a location has been identified as unqualified to navigate on.
     
     See `CLLocation.isQualified` for more information about what qualifies a location.
     
     - parameter routeController: The route controller that discarded the location.
     - parameter location: The location that will be discarded.
     - return: If `true`, the location is discarded and the `RouteController` will not consider it. If `false`, the location will not be thrown out.
     */
    @objc(routeController:shouldDiscardLocation:)
    optional func routeController(_ routeController: RouteController, shouldDiscard location: CLLocation) -> Bool
    
    /**
     Called immediately after the route controller receives a new route.
     
     This method is called after `routeController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidReroute` notification being posted.
     
     - parameter routeController: The route controller that has calculated a new route.
     - parameter route: The new route.
     */
    @objc(routeController:didRerouteAlongRoute:)
    optional func routeController(_ routeController: RouteController, didRerouteAlong route: Route)
    
    /**
     Called when the route controller fails to receive a new route.
     
     This method is called after `routeController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidFailToReroute` notification being posted.
     
     - parameter routeController: The route controller that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    @objc(routeController:didFailToRerouteWithError:)
    optional func routeController(_ routeController: RouteController, didFailToRerouteWith error: Error)
    
    /**
     Called when the route controller’s location manager receives a location update.
     
     These locations may be modified due to replay or simulation and can
     also derive from regular location updates from a `CLLocationManager`.
     
     - parameter routeController: The route controller that received the new locations.
     - parameter locations: The locations that were received from the associated location manager.
     */
    @objc(routeController:didUpdateLocations:)
    optional func routeController(_ routeController: RouteController, didUpdate locations: [CLLocation])
    
    /**
     Called when the route controller arrives at a waypoint.
     
     You can implement this method to prevent the route controller from automatically advancing to the next leg. For example, you can and show an interstitial sheet upon arrival and pause navigation by returning `false`, then continue the route when the user dismisses the sheet. If this method is unimplemented, the route controller automatically advances to the next leg when arriving at a waypoint.
     
     - postcondition: If you return false, you must manually advance to the next leg: obtain the value of the `routeProgress` property, then increment the `RouteProgress.legIndex` property.
     - parameter routeController: The route controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to advance to the next leg, if any, or false to remain on the completed leg.
     */
    @objc(routeController:didArriveAtWaypoint:)
    optional func routeController(_ routeController: RouteController, didArriveAt waypoint: Waypoint) -> Bool
    
    /**
     Called when the route controller arrives at a waypoint.
     
     You can implement this method to allow the route controller to continue check and reroute the user if needed. By default, the user will not be rerouted when arriving at a waypoint.
     
     - parameter routeController: The route controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to prevent the route controller from checking if the user should be rerouted.
     */
    @objc(routeController:shouldPreventReroutesWhenArrivingAtWaypoint:)
    optional func routeController(_ routeController: RouteController, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool
    
    
    /**
     Called when the route controller will disable battery monitoring.
     
     Implementing this method will allow developers to change whether battery monitoring is disabled when `RouteController` is deinited.
     
     - parameter routeController: The route controller that will change the state of battery monitoring.
     - returns: A bool indicating whether to disable battery monitoring when the RouteController is deinited.
     */
    @objc(routeControllerShouldDisableBatteryMonitoring:)
    optional func routeControllerShouldDisableBatteryMonitoring(_ routeController: RouteController) -> Bool
}
