import Foundation
import CoreLocation
import MapboxDirections
import os.log

/**
 A navigation service delegate interacts with one or more `NavigationService` instances (such as `MapboxNavigationService` objects) during turn-by-turn navigation. This protocol is the main way that your application can synchronize its state with the SDK’s location-related functionality. Each of the protocol’s methods is optional.
 
 As the user progresses along a route, a navigation service informs its delegate about significant events as they occur, and the delegate has opportunities to influence the route and its presentation. For example, when the navigation service reports that the user has arrived at the destination, your delegate implementation could present information about the destination. It could also customize individual visual or spoken instructions along the route by returning modified instruction objects.
 
 Assign a `NavigationServiceDelegate` instance to the `NavigationService.delegate` property of the navigation service before you start the service.
 
 The `RouterDelegate` protocol defines corresponding methods so that a `Router` instance can interact with an object that is both a router delegate and a navigation service, which in turn interacts with a navigation service delegate. Additionally, several location-related methods in this protocol have corresponding methods in the `NavigationViewControllerDelegate` protocol, which can be convenient if you are using the navigation service in conjunction with a `NavigationViewController`. Normally, you would either implement methods in `NavigationServiceDelegate` or `NavigationViewControllerDelegate` but not `RouterDelegate`.
 
 - seealso: NavigationViewControllerDelegate
 - seealso: RouterDelegate
 */
public protocol NavigationServiceDelegate: AnyObject, UnimplementedLogging {
    
    // MARK: Rerouting Logic
    
    /**
     Returns whether the navigation service should be allowed to calculate a new route.
     
     If implemented, this method is called as soon as the navigation service detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `navigationService(_:willRerouteFrom:)` will be called immediately afterwards.
     
     - parameter service: The navigation service that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the navigation service to calculate a new route; false to keep tracking the current route.
     */
    func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool
    
    /**
     Called immediately before the navigation service calculates a new route.
     
     This method is called after `navigationService(_:shouldRerouteFrom:)` is called, simultaneously with the `Notification.Name.routeControllerWillReroute` notification being posted, and before `navigationService(_:didRerouteAlong:)` is called.
     
     - parameter service: The navigation service that will calculate a new route.
     - parameter location: The user’s current location.
     */
    func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation)
    
    /**
     Called when a location has been identified as unqualified to navigate on.
     
     See `CLLocation.isQualified` for more information about what qualifies a location.
     
     - parameter service: The navigation service that discarded the location.
     - parameter location: The location that will be discarded.
     - returns: If `true`, the location is discarded and the `NavigationService` will not consider it. If `false`, the location will not be thrown out.
     */
    func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool
    
    /**
     Called immediately after the navigation service receives a new route.
     
     This method is called after `navigationService(_:willRerouteFrom:)` and simultaneously with the `Notification.Name.routeControllerDidReroute` notification being posted.
     
     - parameter service: The navigation service that has calculated a new route.
     - parameter route: The new route.
     */
    func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool)
    
    /**
     Called when the navigation service fails to receive a new route.
     
     This method is called after `navigationService(_:willRerouteFrom:)` and simultaneously with the `Notification.Name.routeControllerDidFailToReroute` notification being posted.
     
     - parameter service: The navigation service that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error)
    
    // MARK: Monitoring Route Progress and Updates
    
    /**
     Called immediately after the navigation service refreshes the route.
     
     This method is called simultaneously with the `Notification.Name.routeControllerDidRefreshRoute` notification being posted.
     
     - parameter service: The navigation service that has refreshed the route.
     - parameter routeProgress: The route progress updated with the refreshed route.
     */
    func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress)
    
    /**
     Called when the navigation service updates the route progress model.
     
     - parameter service: The navigation service that received the new locations.
     - parameter progress: the RouteProgress model that was updated.
     - parameter location: the guaranteed location, possibly snapped, associated with the progress update.
     - parameter rawLocation: the raw location, from the location manager, associated with the progress update.
     */
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation)
    
    /**
     Called when the navigation service arrives at a waypoint.
     
     You can implement this method to allow the navigation service to continue check and reroute the user if needed. By default, the user will not be rerouted when arriving at a waypoint.
     
     - parameter service: The navigation service that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to prevent the navigation service from checking if the user should be rerouted.
     */
    func navigationService(_ service: NavigationService, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool
    
    /**
     Called as the navigation service approaches a waypoint.
     
     This message is sent, once per progress update, as the user is approaching a waypoint. You can use this to cue UI, to do network pre-loading, etc.
     - parameter service: The Navigation service that is detecting the destination approach.
     - parameter waypoint: The waypoint that the service is arriving at.
     - parameter remainingTimeInterval: The estimated number of seconds until arrival.
     - parameter distance: The current distance from the waypoint, in meters.
     - important: This method will likely be called several times as you approach a destination. If only one consumption of this method is desired, then usage of an internal flag is recommended.
     */
    func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval:TimeInterval, distance: CLLocationDistance)
    
    /**
     Called when the navigation service arrives at a waypoint.
     
     You can implement this method to prevent the navigation service from automatically advancing to the next leg. For example, you can and show an interstitial sheet upon arrival and pause navigation by returning `false`, then continue the route when the user dismisses the sheet. If this method is unimplemented, the navigation service automatically advances to the next leg when arriving at a waypoint.
     
     - postcondition: If you return false, you must manually advance to the next leg using `Router.advanceLegIndex(completionHandler:)` method.
     - parameter service: The navigation service that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to advance to the next leg, if any, or false to remain on the completed leg.
     */
    func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool
    
    /**
     Called when the navigation service detects that the user has passed a point at which an instruction should be displayed.
     - parameter service: The navigation service that passed the instruction point.
     - parameter instruction: The instruction to be presented.
     - parameter routeProgress: The route progress object that the navigation service is updating.
     */
    func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress)
    
    /**
     Called when the navigation service detects that the user has passed a point at which an instruction should be spoken.
     - parameter service: The navigation service that passed the instruction point.
     - parameter instruction: The instruction to be spoken.
     - parameter routeProgress: The route progress object that the navigation service is updating.
     */
    func navigationService(_ service: NavigationService, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress)
    
    // MARK: Permissions Events
    
    /**
     Called when the location manager's accuracy authorization changed.
     
     You can implement this method to allow the navigation service to check if the user changed accuracy authorization, especially if reducedAccuracy is enabled. This method is only relevant for iOS 14 and above.
     
     - parameter service: The navigation service that will alert that user that reducedAccuracy is enabled.
     - parameter manager: The location manager.
     */
    func navigationServiceDidChangeAuthorization(_ service: NavigationService, didChangeAuthorizationFor locationManager: CLLocationManager)
    
    /**
     Called when the navigation service will disable battery monitoring.
     
     Implementing this method will allow developers to change whether battery monitoring is disabled when `NavigationService` is deinited.
     
     - parameter service: The navigation service that will change the state of battery monitoring.
     - returns: A bool indicating whether to disable battery monitoring when the RouteController is deinited.
     */
    func navigationServiceShouldDisableBatteryMonitoring(_ service: NavigationService) -> Bool
    
    // MARK: Simulating a Route
    
    /**
     Called when the navigation service is about to begin location simulation.
     
     Implementing this method will allow developers to react when "poor GPS" location-simulation is about to start, possibly to show a "Poor GPS" banner in the UI.
     
     - parameter service: The navigation service that will simulate the routes' progress.
     - parameter progress: the current RouteProgress model.
     - parameter reason: The reason the simulation will be initiated. Either manual or poorGPS.
     */
    func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    
    /**
     Called after the navigation service begins location simulation.
     
     Implementing this method will allow developers to react when "poor GPS" location-simulation has started, possibly to show a "Poor GPS" banner in the UI.
     
     - parameter service: The navigation service that is simulating the routes' progress.
     - parameter progress: the current RouteProgress model.
     - parameter reason: The reason the simulation has been initiated. Either manual or poorGPS.
     */
    func navigationService(_ service: NavigationService, didBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    
    /**
     Called when the navigation service is about to end location simulation.
     
     Implementing this method will allow developers to react when "poor GPS" location-simulation is about to end, possibly to hide a "Poor GPS" banner in the UI.
     
     - parameter service: The navigation service that is simulating the routes' progress.
     - parameter progress: the current RouteProgress model.
     - parameter reason: The reason the simulation was initiated. Either manual or poorGPS.
     */
    func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    
    /**
     Called after the navigation service ends location simulation.
     
     Implementing this method will allow developers to react when "poor GPS" location-simulation has ended, possibly to hide a "Poor GPS" banner in the UI.
     
     - parameter service: The navigation service that was simulating the routes' progress.
     - parameter progress: the current RouteProgress model.
     - parameter reason: The reason the simulation was initiated. Either manual or poorGPS.
     */
    func navigationService(_ service: NavigationService, didEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
}

public extension NavigationServiceDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        logUnimplemented( protocolType: NavigationServiceDelegate.self, level: .debug)
        return MapboxNavigationService.Default.shouldRerouteFromLocation
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
        return MapboxNavigationService.Default.shouldDiscardLocation
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .info)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .info)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .info)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
        return MapboxNavigationService.Default.didArriveAtWaypoint
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
        return MapboxNavigationService.Default.shouldPreventReroutesWhenArrivingAtWaypoint
    }
    
    func navigationServiceDidChangeAuthorization(_ service: NavigationService, didChangeAuthorizationFor locationManager: CLLocationManager) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationServiceShouldDisableBatteryMonitoring(_ service: NavigationService) -> Bool {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
        return MapboxNavigationService.Default.shouldDisableBatteryMonitoring
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationService(_ service: NavigationService, didEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        logUnimplemented(protocolType: NavigationServiceDelegate.self, level: .debug)
    }
}
