import Foundation
import CoreLocation
import MapboxDirections

/**
 A router delegate interacts with one or more `Router` instances, such as `RouteController` objects, during turn-by-turn navigation. This protocol is similar to `NavigationServiceDelegate`, which is the main way that your application can synchronize its state with the SDK’s location-related functionality. Normally, you should not need to make a class conform to the `RouterDelegate` protocol or call any of its methods directly, but you would need to call this protocol’s methods if you implement a custom `Router` class.
 
 `MapboxNavigationService` is the only concrete implementation of a router delegate. Implement the `NavigationServiceDelegate` protocol instead to be notified when various significant events occur along the route tracked by a `NavigationService`.
 
 - seealso: MapboxNavigationService
 - seealso: NavigationServiceDelegate
 */
public protocol RouterDelegate: AnyObject, UnimplementedLogging {
    
    // MARK: Rerouting Logic
    
    /**
     Returns whether the router should be allowed to calculate a new route.
     
     If implemented, this method is called as soon as the router detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `router(_:willRerouteFrom:)` will be called immediately afterwards.
     
     - parameter router: The router that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the router to calculate a new route; false to keep tracking the current route.
     */
    func router(_ router: Router, shouldRerouteFrom location: CLLocation) -> Bool

    /**
     Called immediately before the router calculates a new route.

     This method is called after `router(_:shouldRerouteFrom:)` is called, and before `router(_:modifiedOptionsForReroute:)` is called.
     
     - parameter router: The router that will calculate a new route.
     - parameter location: The user’s current location.
     */
    func router(_ router: Router, willRerouteFrom location: CLLocation)
    
    /**
     When reroute is happening, router suggests to customize the `RouteOptions` used to calculate new route.
     
     This method is called after `router(_:willRerouteFrom:)` is called, and before `router(_:didRerouteAlong:)` is called. This method is not called on proactive rerouting.
     
     Default implementation does no modifications.
     
     - parameter router: The router that will calculate a new route.
     - parameter options: Original `RouteOptions`.
     - returns: Modified `RouteOptions`.
     */
    func router(_ router: Router, modifiedOptionsForReroute options: RouteOptions) -> RouteOptions
    
    /**
     Called when a location has been identified as unqualified to navigate on.
     
     See `CLLocation.isQualified` for more information about what qualifies a location.
     
     - parameter router: The router that discarded the location.
     - parameter location: The location that will be discarded.
     - return: If `true`, the location is discarded and the `Router` will not consider it. If `false`, the location will not be thrown out.
     */
    func router(_ router: Router, shouldDiscard location: CLLocation) -> Bool

    /**
     Called immediately after the router receives a new route.
     
     This method is called after `router(_:modifiedOptionsForReroute:)` method is called.
     
     - parameter router: The router that has calculated a new route.
     - parameter route: The new route.
     */
    func router(_ router: Router, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool)

    /**
     Called when router has detected a change in alternative routes list.
     
     - note: `LegacyRouteController` will never report alternative routes updates.
     
     - parameter router: The router reporting an update.
     - parameter updatedAlternatives: Array of actual alternative routes.
     - parameter removedAlternatives: Array of alternative routes which are no longer actual.
     */
    func router(_ router: Router, didUpdateAlternatives updatedAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute])
    
    /**
     Called when router has failed to  change alternative routes list.
     
     - note: `LegacyRouteController` will never report alternative routes updates.
     
     - parameter router: The router reporting an update.
     - parameter error: An error occured.
     */
    func router(_ router: Router, didFailToUpdateAlternatives error: AlternativeRouteError)
    
    /**
     Called when router has detected user taking an alternative route.
     
     This method is called before updating router's main route.
     
     `LegacyRouteController` never calls this method, because it cannot generate routes on the device.
     
     - parameter router: The router that has detected turning to the alternative.
     - parameter route: The alternative route which will be taken as new main.
     - parameter location: The user’s current location.
     */
    func router(_ router: Router, willTakeAlternativeRoute route: Route, at location: CLLocation?)
    
    /**
     Called when router has finished switching to an alternative route
     
     This method is called after `router(_:willTakeAlternativeRoute:)`
     
     - note: `LegacyRouteController` will never report alternative routes updates.
     
     - parameter router: The router that switched to the alternative.
     - parameter location: The user’s current location.
     */
    func router(_ router: Router, didTakeAlternativeRouteAt location: CLLocation?)
    
    /**
     Called when router has failed to take an alternative route.
     
     This method is called after `router(_:willTakeAlternativeRoute:)`.
     
     This call would indicate that something went wrong during setting new main route.
     
     - note: `LegacyRouteController` will never report alternative routes updates.
     
     - parameter router: The router which tried to switch to the alternative.
     - parameter location: The user’s current location.
     */
    func router(_ router: Router, didFailToTakeAlternativeRouteAt location: CLLocation?)
    
    /**
     Called when router has automatically switched to the coincide online route.
     
     - note: `LegacyRouteController` will never do that.
     
     - parameter router: The router reporting an update.
     - parameter coincideRoute: A route taken.
     */
    func router(_ router: Router, didSwitchToCoincidentOnlineRoute coincideRoute: Route)
    
    /**
     Called when the router fails to receive a new route.
     
     This method is called after `router(_:modifiedOptionsForReroute:)`.
     
     - parameter router: The router that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    func router(_ router: Router, didFailToRerouteWith error: Error)

    // MARK: Monitoring Route Progress and Updates
    
    /**
     Called immediately after the router refreshes the route.
     
     - parameter router: The router that has refreshed the route.
     - parameter routeProgress: The route progress updated with the refreshed route.
     */
    func router(_ router: Router, didRefresh routeProgress: RouteProgress)
    
    /**
     Called when the router updates the route progress model.
     
     - parameter router: The router that received the new locations.
     - parameter progress: the RouteProgress model that was updated.
     - parameter location: the guaranteed location, possibly snapped, associated with the progress update.
     - parameter rawLocation: the raw location, from the location manager, associated with the progress update.
     */
    func router(_ router: Router, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation)
    
    /**
     Called when the router arrives at a waypoint.
     
     You can implement this method to allow the router to continue check and reroute the user if needed. By default, the user will not be rerouted when arriving at a waypoint.
     
     - parameter router: The router that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to prevent the router from checking if the user should be rerouted.
     */
    func router(_ router: Router, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool
    
    /**
     Called as the router approaches a waypoint.
     
     This message is sent, once per progress update, as the user is approaching a waypoint. You can use this to cue UI, to do network pre-loading, etc.
     - parameter router: The router that is detecting the destination approach.
     - parameter waypoint: The waypoint that the service is arriving at.
     - parameter remainingTimeInterval: The estimated number of seconds until arrival.
     - parameter distance: The current distance from the waypoint, in meters.
     - important: This method will likely be called several times as you approach a destination. If only one consumption of this method is desired, then usage of an internal flag is recommended.
     */
    func router(_ router: Router, willArriveAt waypoint: Waypoint, after remainingTimeInterval:TimeInterval, distance: CLLocationDistance)
    
    /**
     Called when the router arrives at a waypoint.
     
     You can implement this method to prevent the router from automatically advancing to the next leg. For example, you can and show an interstitial sheet upon arrival and pause navigation by returning `false`, then continue the route when the user dismisses the sheet. If this method is unimplemented, the router automatically advances to the next leg when arriving at a waypoint.
     
     - postcondition: If you return false, you must manually advance to the next leg using `Router.advanceLegIndex(completionHandler:)` method.
     - parameter router: The router that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to advance to the next leg, if any, or false to remain on the completed leg.
     */
    func router(_ router: Router, didArriveAt waypoint: Waypoint) -> Bool
    
    /**
     Called when the router detects that the user has passed a point at which an instruction should be displayed.
     - parameter router: The router that passed the instruction point.
     - parameter instruction: The instruction to be presented.
     - parameter routeProgress: The route progress object that the router is updating.
     */
    func router(_ router: Router, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress)
    
    /**
     Called when the router detects that the user has passed a point at which an instruction should be spoken.
     - parameter router: The router that passed the instruction point.
     - parameter instruction: The instruction to be spoken.
     - parameter routeProgress: The route progress object that the router is updating.
     */
    func router(_ router: Router, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress)

    // MARK: Permissions Events
    
    /**
     Called when the router will disable battery monitoring.
     
     Implementing this method will allow developers to change whether battery monitoring is disabled when the `Router` is deinited.
     
     - parameter router: The router that will change the state of battery monitoring.
     - returns: A bool indicating whether to disable battery monitoring when the RouteController is deinited.
     */
    func routerShouldDisableBatteryMonitoring(_ router: Router) -> Bool
}

public extension RouterDelegate {
    func router(_ router: Router, shouldRerouteFrom location: CLLocation) -> Bool {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
        return RouteController.DefaultBehavior.shouldRerouteFromLocation
    }
    
    func router(_ router: Router, willRerouteFrom location: CLLocation) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, modifiedOptionsForReroute options: RouteOptions) -> RouteOptions {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
        return options
    }
    
    func router(_ router: Router, shouldDiscard location: CLLocation) -> Bool {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
        return RouteController.DefaultBehavior.shouldDiscardLocation
    }
    
    func router(_ router: Router, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .info)
    }
    
    func router(_ router: Router, didFailToRerouteWith error: Error) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .info)
    }
    
    func router(_ router: Router, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, didArriveAt waypoint: Waypoint) -> Bool {
        logUnimplemented(protocolType: RouterDelegate.self, level: .info)
        return RouteController.DefaultBehavior.didArriveAtWaypoint
    }
    
    func router(_ router: Router, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        logUnimplemented(protocolType: RouterDelegate.self, level: .info)
        return RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint
    }
    
    func routerShouldDisableBatteryMonitoring(_ router: Router) -> Bool {
        logUnimplemented(protocolType: RouterDelegate.self, level: .info)
        return RouteController.DefaultBehavior.shouldDisableBatteryMonitoring
    }
    
    func router(_ router: Router, didUpdateAlternatives updatedAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute]) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, didFailToUpdateAlternatives error: AlternativeRouteError) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, willTakeAlternativeRoute route: Route, at location: CLLocation?) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, didTakeAlternativeRouteAt location: CLLocation?) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, didFailToTakeAlternativeRouteAt location: CLLocation?) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
    
    func router(_ router: Router, didSwitchToCoincidentOnlineRoute coincideRoute: Route) {
        logUnimplemented(protocolType: RouterDelegate.self, level: .debug)
    }
}

