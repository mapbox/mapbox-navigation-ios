import Foundation
import CoreLocation
import MapboxDirections

@objc public protocol NavigationServiceDelegate {
    /**
     Returns whether the navigation service should be allowed to calculate a new route.
     
     If implemented, this method is called as soon as the navigation service detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `navigationService(_:willRerouteFrom:)` will be called immediately afterwards.
     
     - parameter service: The navigation service that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the navigation service to calculate a new route; false to keep tracking the current route.
     */
    @objc(navigationService:shouldRerouteFromLocation:)
    optional func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool
    
    /**
     Called immediately before the navigation service calculates a new route.
     
     This method is called after `navigationService(_:shouldRerouteFrom:)` is called, simultaneously with the `NavigationServiceWillReroute` notification being posted, and before `navigationService(_:didRerouteAlong:)` is called.
     
     - parameter service: The navigation service that will calculate a new route.
     - parameter location: The user’s current location.
     */
    @objc(navigationService:willRerouteFromLocation:)
    optional func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation)
    
    /**
     Called when a location has been identified as unqualified to navigate on.
     
     See `CLLocation.isQualified` for more information about what qualifies a location.
     
     - parameter service: The navigation service that discarded the location.
     - parameter location: The location that will be discarded.
     - return: If `true`, the location is discarded and the `NavigationService` will not consider it. If `false`, the location will not be thrown out.
     */
    @objc(navigationService:shouldDiscardLocation:)
    optional func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool
    
    /**
     Called immediately after the navigation service receives a new route.
     
     This method is called after `navigationService(_:willRerouteFrom:)` and simultaneously with the `NavigationServiceDidReroute` notification being posted.
     
     - parameter service: The navigation service that has calculated a new route.
     - parameter route: The new route.
     */
    @objc(navigationService:didRerouteAlongRoute:at:proactive:)
    optional func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool)
    
    /**
     Called when the navigation service fails to receive a new route.
     
     This method is called after `navigationService(_:willRerouteFrom:)` and simultaneously with the `NavigationServiceDidFailToReroute` notification being posted.
     
     - parameter service: The navigation service that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    @objc(navigationService:didFailToRerouteWithError:)
    optional func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error)
    
    /**
     Called when the navigation service updates the route progress model.
     
     - parameter service: The navigation service that received the new locations.
     - parameter progress: the RouteProgress model that was updated.
     - parameter location: the guaranteed location, possibly snapped, associated with the progress update.
     - parameter rawLocation: the raw location, from the location manager, associated with the progress update.
     */
    
    @objc(navigationService:didUpdateProgress:withLocation:rawLocation:)
    optional func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation)
    
    /**
     Called when the navigation service detects that the user has passed a point at which an instruction should be displayed.
     - parameter service: The navigation service that passed the instruction point.
     - parameter instruction: The instruction to be presented.
     - parameter routeProgress: The route progress object that the navigation service is updating.
    */
    @objc(navigationService:didPassVisualInstructionPoint:routeProgress:)
    optional func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress)
    
    
    /**
     Called when the navigation service detects that the user has passed a point at which an instruction should be spoken.
     - parameter service: The navigation service that passed the instruction point.
     - parameter instruction: The instruction to be spoken.
     - parameter routeProgress: The route progress object that the navigation service is updating.
     */
    @objc(navigationService:didPassSpokenInstructionPoint:routeProgress:)
    optional func navigationService(_ service: NavigationService, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress)
    
    /**
     Called as the navigation service approaches a waypoint.
     
     This message is sent, once per progress update, as the user is approaching a waypoint. You can use this to cue UI, to do network pre-loading, etc.
     - parameter service: The Navigation service that is detecting the destination approach.
     - parameter waypoint: The waypoint that the service is arriving at.
     - parameter remainingTimeInterval: The estimated number of seconds until arrival.
     - parameter distance: The current distance from the waypoint, in meters.
     - important: This method will likely be called several times as you approach a destination. If only one consumption of this method is desired, then usage of an internal flag is recommended.
     */
    
    @objc(navigationService:willArriveAtWaypoint:after:distance:)
    optional func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval:TimeInterval, distance: CLLocationDistance)
    
    /**
     Called when the navigation service arrives at a waypoint.
     
     You can implement this method to prevent the navigation service from automatically advancing to the next leg. For example, you can and show an interstitial sheet upon arrival and pause navigation by returning `false`, then continue the route when the user dismisses the sheet. If this method is unimplemented, the navigation service automatically advances to the next leg when arriving at a waypoint.
     
     - postcondition: If you return false, you must manually advance to the next leg: obtain the value of the `routeProgress` property, then increment the `RouteProgress.legIndex` property.
     - parameter service: The navigation service that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to advance to the next leg, if any, or false to remain on the completed leg.
     */
    @objc(navigationService:didArriveAtWaypoint:)
    optional func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool
    
    /**
     Called when the navigation service arrives at a waypoint.
     
     You can implement this method to allow the navigation service to continue check and reroute the user if needed. By default, the user will not be rerouted when arriving at a waypoint.
     
     - parameter service: The navigation service that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to prevent the navigation service from checking if the user should be rerouted.
     */
    @objc(navigationService:shouldPreventReroutesWhenArrivingAtWaypoint:)
    optional func navigationService(_ service: NavigationService, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool
    
    
    /**
     Called when the navigation service will disable battery monitoring.
     
     Implementing this method will allow developers to change whether battery monitoring is disabled when `NavigationService` is deinited.
     
     - parameter service: The navigation service that will change the state of battery monitoring.
     - returns: A bool indicating whether to disable battery monitoring when the RouteController is deinited.
     */
    @objc(navigationServiceShouldDisableBatteryMonitoring:)
    optional func navigationServiceShouldDisableBatteryMonitoring(_ service: NavigationService) -> Bool
    
    
    /**
     Called when the navigation service is about to begin location simulation.
     
     Implementing this method will allow developers to react when "poor GPS" location-simulation is about to start, possibly to show a "Poor GPS" banner in the UI.
     
     - parameter service: The navigation service that will simulate the routes' progress.
     - parameter progress: the current RouteProgress model.
     - parameter reason: The reason the simulation will be initiated. Either manual or poorGPS.
     */
    @objc optional func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    
    /**
     Called after the navigation service begins location simulation.
     
     Implementing this method will allow developers to react when "poor GPS" location-simulation has started, possibly to show a "Poor GPS" banner in the UI.
     
     - parameter service: The navigation service that is simulating the routes' progress.
     - parameter progress: the current RouteProgress model.
     - parameter reason: The reason the simulation has been initiated. Either manual or poorGPS.
     */
    @objc optional func navigationService(_ service: NavigationService, didBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    
    /**
     Called when the navigation service is about to end location simulation.
     
     Implementing this method will allow developers to react when "poor GPS" location-simulation is about to end, possibly to hide a "Poor GPS" banner in the UI.
     
     - parameter service: The navigation service that is simulating the routes' progress.
     - parameter progress: the current RouteProgress model.
     - parameter reason: The reason the simulation was initiated. Either manual or poorGPS.
     */
    @objc optional func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    
    /**
     Called after the navigation service ends location simulation.
     
     Implementing this method will allow developers to react when "poor GPS" location-simulation has ended, possibly to hide a "Poor GPS" banner in the UI.
     
     - parameter service: The navigation service that was simulating the routes' progress.
     - parameter progress: the current RouteProgress model.
     - parameter reason: The reason the simulation was initiated. Either manual or poorGPS.
     */
    @objc optional func navigationService(_ service: NavigationService, didEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
}
