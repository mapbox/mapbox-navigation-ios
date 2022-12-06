import CoreLocation
import CoreGraphics
import Foundation
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation

/**
 The `NavigationViewControllerDelegate` protocol provides methods for configuring the map view shown by a `NavigationViewController` and responding to the cancellation of a navigation session.
 
 For convenience, several location-related methods in the `NavigationServiceDelegate` protocol have corresponding methods in this protocol.
 */
public protocol NavigationViewControllerDelegate: VisualInstructionDelegate {
    
    // MARK: Monitoring Route Progress
    
    /**
     Called when the navigation view controller is dismissed, such as when the user ends a trip.
     
     - parameter navigationViewController: The navigation view controller that was dismissed.
     - parameter canceled: True if the user dismissed the navigation view controller by tapping the Cancel button; false if the navigation view controller dismissed by some other means.
     */
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool)
    
    /**
     Called when movement of the user updates the route progress model.
     
     - parameter navigationViewController: The ViewController that received the new locations.
     - parameter progress: the RouteProgress model that was updated.
     - parameter location: the guaranteed location, possibly snapped, associated with the progress update.
     - parameter rawLocation: the raw location, from the location manager, associated with the progress update.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation)
    
    // MARK: Interaction With Waypoints
    
    /**
     Tells the receiver that the final destination `PointAnnotation` was added to the `NavigationViewController`.
     
     - parameter navigationViewController: The `NavigationViewController` object.
     - parameter finalDestinationAnnotation: The point annotation that was added to the map view.
     - parameter pointAnnotationManager: The object that manages the point annotation in the map view.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didAdd finalDestinationAnnotation: PointAnnotation, pointAnnotationManager: PointAnnotationManager)
    
    /**
     Called as the user approaches a waypoint.
     
     This message is sent, once per progress update, as the user is approaching a waypoint. You can use this to cue UI, to do network pre-loading, etc.
     - parameter navigationViewController: The Navigation VC that is detecting the users' approach.
     - parameter waypoint: The waypoint that the service is arriving at.
     - parameter remainingTimeInterval: The estimated number of seconds until arrival.
     - parameter distance: The current distance from the waypoint, in meters.
     - note: This method will likely be called several times as you approach a destination. To respond to the user’s arrival only once, your delegate can define a property that keeps track of whether this method has already been called for the given waypoint.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance)
    
    /**
     Called when the user arrives at the destination waypoint for a route leg.
     
     This method is called when the navigation view controller arrives at the waypoint. You can implement this method to prevent the navigation view controller from automatically advancing to the next leg. For example, you can and show an interstitial sheet upon arrival and pause navigation by returning `false`, then continue the route when the user dismisses the sheet. If this method is unimplemented, the navigation view controller automatically advances to the next leg when arriving at a waypoint.

     - postcondition: If you return `false` within this method, you must manually advance to the next leg using the `Router.advanceLegIndex(completionHandler:)` method. Obtain `Router` via the `NavigationViewController.navigationService` and `NavigationService.router` properties.
     - parameter navigationViewController: The navigation view controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the user has arrived at.
     - returns: True to automatically advance to the next leg, or false to remain on the now completed leg.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool
    
    /**
     Tells the receiver that a waypoint was selected.
     
     - parameter navigationViewController: The `NavigationViewController` object.
     - parameter waypoint: The waypoint that was selected.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSelect waypoint: Waypoint)
    
    // MARK: Rerouting and Refreshing the Route
    
    /**
     Returns whether the navigation view controller should be allowed to calculate a new route.
     
     If implemented, this method is called as soon as the navigation view controller detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `navigationViewController(_:willRerouteFrom:)` will be called immediately afterwards.
     
     - parameter navigationViewController: The navigation view controller that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the navigation view controller to calculate a new route; false to keep tracking the current route.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool

    /**
     Asks permission to proceed with found proactive reroute and apply it as main route.
     
     If implemented, this method is called as soon as the navigation view controller detects route faster than the current one. This only happens if `Router.reroutesProactively` is set to `true` (default). Calling provided `completion` results in new route to be set, without triggering usual rerouting delegate methods.
     
     - parameter navigationViewController: The navigation view controller that has detected faster new route
     - parameter location: The user’s current location.
     - parameter route: The route found.
     - parameter completion: Completion to be called to allow the navigation view controller to apply a new route; Ignoring calling the completion will ignore the faster route aswell.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldProactivelyRerouteFrom location: CLLocation, to route: Route, completion: @escaping () -> Void)
    
    /**
     Called when the user arrives at a waypoint.

     Return false to continue checking if reroute is needed. By default, the user will not be rerouted when arriving at a waypoint.
     
     - parameter navigationViewController: The navigation view controller that has detected the need to calculate a new route.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to prevent reroutes.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool

    /**
     Called immediately before the navigation view controller calculates a new route.
     
     This method also allows customizing the rerouting by providing custom `RouteResponse`. SDK will then treat it as if it was fetched as usual and apply as a reroute.
     
     - note: Multiple method calls will not interrupt the first ongoing request.
     
     This method is called after `navigationViewController(_:shouldRerouteFrom:)` is called, simultaneously with the `Notification.Name.routeControllerWillReroute` notification being posted, and before `navigationViewController(_:modifiedOptionsForReroute:)` is called.
     
     - parameter navigationViewController: The navigation view controller that will calculate a new route.
     - parameter location: The user’s current location.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willRerouteFrom location: CLLocation?)
    
    /**
     When reroute is happening, navigation view controller suggests to customize the `RouteOptions` used to calculate new route.
     
     This method is called after `navigationViewController(_:willRerouteFrom:)` is called, and before `navigationViewController(_:didRerouteAlong:)` is called. This method is not called on proactive rerouting.
     
     Default implementation does no modifications.
     
     - parameter navigationViewController: The navigation view controller that will calculate a new route.
     - parameter options: Original `RouteOptions`.
     - returns: Modified `RouteOptions`.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, modifiedOptionsForReroute options: RouteOptions) -> RouteOptions
    
    /**
     Called immediately after the navigation view controller receives a new route.
     
     This method is called after `navigationViewController(_:modifiedOptionsForReroute:)` and simultaneously with the `Notification.Name.routeControllerDidReroute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has calculated a new route.
     - parameter route: The new route.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route)
    
    /**
     Called when navigation view controller has detected a change in alternative routes list.
     
     - parameter navigationViewController: The navigation view controller reporting an update.
     - parameter updatedAlternatives: Array of actual alternative routes.
     - parameter removedAlternatives: Array of alternative routes which are no longer actual.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdateAlternatives updatedAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute])
    
    /**
     Called when navigation view controller has failed to change alternative routes list.
     
     - parameter navigationViewController: The navigation view controller reporting an update.
     - parameter error: An error occured.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToUpdateAlternatives error: AlternativeRouteError)
    
    /**
     Called when navigation view controller has automatically switched to the coincide online route.
     
     - parameter navigationViewController: The navigation view controller reporting an update.
     - parameter coincideRoute: A route taken.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSwitchToCoincidentOnlineRoute coincideRoute: Route)
    
    /**
     Called when navigation view controller has detected user taking an alternative route.
     
     This method is called before updating main route.
     
     - parameter navigationViewController: The navigation view controller that has detected turning to the alternative.
     - parameter route: The alternative route which will be taken as new main.
     - parameter location: The user’s current location.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willTakeAlternativeRoute route: Route, at location: CLLocation?)
    
    /**
     Called when navigation view controller has finished switching to an alternative route
     
     This method is called after `navigationViewController(_:willTakeAlternativeRoute:)`
     
     - parameter navigationViewController: The navigation view controller that switched to the alternative.
     - parameter location: The user’s current location.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didTakeAlternativeRouteAt location: CLLocation?)
    
    /**
     Called when navigation view controller has failed to take an alternative route.
     
     This method is called after `navigationViewController(_:willTakeAlternativeRoute:)`.
     
     This call would indicate that something went wrong during setting new main route.
     
     - parameter navigationViewController: The navigation view controller which tried to switch to the alternative.
     - parameter location: The user’s current location.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToTakeAlternativeRouteAt location: CLLocation?)
    
    /**
     Tells the receiver that the user has selected a continuous alternative route by interacting with the map view.
     
     Continuous alternatives are all non-primary routes, reported during the navigation session.
     
     - parameter navigationViewController: The `NavigationViewController` object.
     - parameter continuousAlternative: The route that was selected.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSelect continuousAlternative: AlternativeRoute)
    
    /**
     Called when the navigation view controller fails to receive a new route.
     
     This method is called after `navigationViewController(_:modifiedOptionsForReroute:)` and simultaneously with the `Notification.Name.routeControllerDidFailToReroute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToRerouteWith error: Error)
    
    /**
     Called immediately after the navigation view controller refreshes the route.
     
     This method is called simultaneously with the `Notification.Name.routeControllerDidRefreshRoute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has refreshed the route.
     - parameter routeProgress: The updated route progress with the refreshed route.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didRefresh routeProgress: RouteProgress)
    
    // MARK: Customizing the Route Elements
    
    /**
     Returns an `LineLayer` that determines the appearance of the route line.
     
     If this method is not implemented, the navigation view controller’s map view draws the route line using default `LineLayer`.
     
     - parameter navigationViewController: The `NavigationViewController` object, on surface of which route line is drawn.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied to the route line.
     
     - seealso: `NavigationMapViewDelegate.navigationMapView(_:routeLineLayerWithIdentifier:sourceIdentifier:)`,
     `CarPlayManagerDelegate.carPlayManager(_:routeLineLayerWithIdentifier:sourceIdentifier:for:)`.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer?
    
    /**
     Returns an `LineLayer` that determines the appearance of the casing around the route line.
     
     If this method is not implemented, the navigation view controller’s map view draws the casing for the route line using default `LineLayer`.
     
     - parameter navigationViewController: The `NavigationViewController` object, on surface of which route line is drawn.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied as a casing around the route line.
     
     - seealso: `NavigationMapViewDelegate.navigationMapView(_:routeCasingLineLayerWithIdentifier:sourceIdentifier:)`,
     `CarPlayManagerDelegate.carPlayManager(_:routeCasingLineLayerWithIdentifier:sourceIdentifier:for:)`.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer?
    
    /**
     Returns an `LineLayer` that determines the appearance of the restricted areas portions of the route line.
     
     If this method is not implemented, the navigation view controller’s map view draws the areas using default `LineLayer`.
     
     
     - parameter navigationViewController: The `NavigationViewController` object, on surface of which route line is drawn.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied as restricted areas on the route line.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, routeRestrictedAreasLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer?
    
    /**
     Asks the receiver to adjust the default layer which will be added to the map view and return a `Layer`.
     
     If this method is not implemented, the navigation view controller’s map view draws the default `layer`.
     
     - parameter navigationViewController: The `NavigationViewController` object, on surface of which route line is drawn.
     - parameter layer: A default `Layer` generated by the navigationViewController.
     - returns: A `Layer` after adjusted and will be added to the navigation view controller’s map view by `MapboxNavigation`.
     
     - seealso: `NavigationMapViewDelegate.navigationMapView(_:willAdd:)`,
     `CarPlayManagerDelegate.carPlayManager(_:willAdd:for:)`.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willAdd layer: Layer) -> Layer?
    
    /**
     Returns an `CircleLayer` that marks the location of each destination along the route when there are multiple destinations. The returned layer is added to the map below the layer returned by `navigationViewController(_:waypointSymbolLayerWithIdentifier:sourceIdentifier:)`.
     
     If this method is unimplemented, the navigation view controller’s map view marks each destination waypoint with a circle.
     
     - parameter navigationViewController: The `NavigationViewController` object.
     - parameter identifier: The `CircleLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
     - returns: A `CircleLayer` that the map applies to all waypoints.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer?
    
    /**
     Returns a `SymbolLayer` that places an identifying symbol on each destination along the route when there are multiple destinations. The returned layer is added to the map above the layer returned by `navigationViewController(_:waypointCircleLayerWithIdentifier:sourceIdentifier:)`.
     
     If this method is unimplemented, the navigation view controller’s map view labels each destination waypoint with a number, starting with 1 at the first destination, 2 at the second destination, and so on.
     
     - parameter navigationViewController: The `NavigationViewController` object.
     - parameter identifier: The `SymbolLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the waypoint data that this method would style.
     - returns: A `SymbolLayer` that the map applies to all waypoint symbols.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer?
    
    /**
     Returns a `FeatureCollection` that represents the destination waypoints along the route (that is, excluding the origin).
     
     If this method is unimplemented, the navigation view controller's map view draws the waypoints using default `FeatureCollection`.
     
     - parameter navigationViewController: The `NavigationViewController` object.
     - parameter waypoints: The waypoints to be displayed on the map.
     - parameter legIndex: Index, which determines for which `RouteLeg` `Waypoint` will be shown.
     - returns: Optionally, a `FeatureCollection` that defines the shape of the waypoint, or `nil` to use default behavior.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection?
    
    /**
     Called to allow the delegate to customize the contents of the road name label that is displayed towards the bottom of the map view.
     
     This method is called on each location update. By default, the label displays the name of the road the user is currently traveling on.
     
     - parameter navigationViewController: The navigation view controller that will display the road name.
     - parameter location: The user’s current location.
     - returns: The road name to display in the label, or nil to hide the label.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, roadNameAt location: CLLocation) -> String?
    
    // MARK: Filtering Location Updates
    
    /**
     Allows the delegate to decide whether to ignore a location update.
     
     This method is called on every location update. By default, the navigation view controller ignores certain location updates that appear to be unreliable, as determined by the `CLLocation.isQualified` property.
     
     - parameter navigationViewController: The navigation view controller that discarded the location.
     - parameter location: The location that will be discarded.
     - returns: If `true`, the location is discarded and the `NavigationViewController` will not consider it. If `false`, the location will not be thrown out.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool
    
    /**
     Called to notify that the user submitted the end of route feedback.
     
     - parameter navigationViewController: The `NavigationViewController` object.
     - parameter feedback: The `EndOfRouteFeedback` that was submitted by the user.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSubmitArrivalFeedback feedback: EndOfRouteFeedback)
}

public extension NavigationViewControllerDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .info)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return RouteController.DefaultBehavior.didArriveAtWaypoint
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSelect waypoint: Waypoint) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return RouteController.DefaultBehavior.shouldRerouteFromLocation
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldProactivelyRerouteFrom location: CLLocation, to route: Route, completion: @escaping () -> Void) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        if RouteController.DefaultBehavior.shouldProactivelyRerouteFromLocation {
            completion()
        }
    }

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return RouteController.DefaultBehavior.shouldRerouteFromLocation
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willRerouteFrom location: CLLocation?) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, modifiedOptionsForReroute options: RouteOptions) -> RouteOptions {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return options
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdateAlternatives updatedAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute]) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToUpdateAlternatives error: AlternativeRouteError) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSwitchToCoincidentOnlineRoute coincideRoute: Route) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willTakeAlternativeRoute route: Route, at location: CLLocation?) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didTakeAlternativeRouteAt location: CLLocation?) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToTakeAlternativeRouteAt location: CLLocation?) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSelect continuousAlternative: AlternativeRoute) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToRerouteWith error: Error) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didRefresh routeProgress: RouteProgress) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, routeRestrictedAreasLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willAdd layer: Layer) -> Layer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return RouteController.DefaultBehavior.shouldDiscardLocation
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, roadNameAt location: CLLocation) -> String? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didAdd finalDestinationAnnotation: PointAnnotation, pointAnnotationManager: PointAnnotationManager) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSubmitArrivalFeedback feedback: EndOfRouteFeedback) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self, level: .debug)
    }
}
