import Foundation
import MapboxDirections
import MapboxCoreNavigation

/**
 The `NavigationViewControllerDelegate` protocol provides methods for configuring the map view shown by a `NavigationViewController` and responding to the cancellation of a navigation session.
 
 For convenience, several location-related methods in the `NavigationServiceDelegate` protocol have corresponding methods in this protocol.
 */
public protocol NavigationViewControllerDelegate: VisualInstructionDelegate{
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
     
     - postcondition: If you return `false` within this method, you must manually advance to the next leg: obtain the value of the `navigationService` and its `NavigationService.routeProgress` property, then increment the `RouteProgress.legIndex` property.
     - parameter navigationViewController: The navigation view controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the user has arrived at.
     - returns: True to automatically advance to the next leg, or false to remain on the now completed leg.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool
    
    /**
     Returns whether the navigation view controller should be allowed to calculate a new route.
     
     If implemented, this method is called as soon as the navigation view controller detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `navigationViewController(_:willRerouteFrom:)` will be called immediately afterwards.
     
     - parameter navigationViewController: The navigation view controller that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the navigation view controller to calculate a new route; false to keep tracking the current route.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool
    
    /**
     Called immediately before the navigation view controller calculates a new route.
     
     This method is called after `navigationViewController(_:shouldRerouteFrom:)` is called, simultaneously with the `RouteControllerWillReroute` notification being posted, and before `navigationViewController(_:didRerouteAlong:)` is called.
     
     - parameter navigationViewController: The navigation view controller that will calculate a new route.
     - parameter location: The user’s current location.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willRerouteFrom location: CLLocation?)
    
    /**
     Called immediately after the navigation view controller receives a new route.
     
     This method is called after `navigationViewController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidReroute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has calculated a new route.
     - parameter route: The new route.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route)
    
    /**
     Called when the navigation view controller fails to receive a new route.
     
     This method is called after `navigationViewController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidFailToReroute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToRerouteWith error: Error)


    /**
     Returns an `MGLStyleLayer` that determines the appearance of the main route line.

     If this method is unimplemented, the navigation view controller’s map view draws the route line using an `MGLLineStyleLayer`.
    */
    func navigationViewController(_ navigationViewController: NavigationViewController, mainRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?

    /**
     Returns an `MGLStyleLayer` that determines the appearance of the casing around the main route line.

     If this method is unimplemented, the navigation view controller’s map view draws the casing for the main route line using an `MGLLineStyleLayer`.
    */
    func navigationViewController(_ navigationViewController: NavigationViewController, mainRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?

    /**
     Returns an `MGLStyleLayer` that determines the appearance of alternative route lines.

     If this method is unimplemented, the navigation view controller’s map view draws the alternative route lines using an `MGLLineStyleLayer`.
    */
    func navigationViewController(_ navigationViewController: NavigationViewController, alternativeRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?

    /**
     Returns an `MGLStyleLayer` that determines the appearance of the casing around the alternative route lines.

     If this method is unimplemented, the navigation view controller’s map view draws the casing for the alternative route lines using an `MGLLineStyleLayer`.
    */
    func navigationViewController(_ navigationViewController: NavigationViewController, alternateRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLShape` that represents the path of the route line.
     
     If this method is unimplemented, the navigation view controller’s map view represents the route line using an `MGLPolylineFeature` based on `route`’s `coordinates` property.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor routes: [Route]) -> MGLShape?
    
    /**
     Returns an `MGLShape` that represents the path of the route line’s casing.
     
     If this method is unimplemented, the navigation view controller’s map view represents the route line’s casing using an `MGLPolylineFeature` identical to the one returned by `navigationViewController(_:shapeFor:)`.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, simplifiedShapeFor route: Route) -> MGLShape?
    
    /**
     Returns an `MGLStyleLayer` that marks the location of each destination along the route when there are multiple destinations. The returned layer is added to the map below the layer returned by `navigationViewController(_:waypointSymbolStyleLayerWithIdentifier:source:)`.
     
     If this method is unimplemented, the navigation view controller’s map view marks each destination waypoint with a circle.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLStyleLayer` that places an identifying symbol on each destination along the route when there are multiple destinations. The returned layer is added to the map above the layer returned by `navigationViewController(_:waypointStyleLayerWithIdentifier:source:)`.
     
     If this method is unimplemented, the navigation view controller’s map view labels each destination waypoint with a number, starting with 1 at the first destination, 2 at the second destination, and so on.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLShape` that represents the destination waypoints along the route (that is, excluding the origin).
     
     If this method is unimplemented, the navigation map view represents the route waypoints using `navigationViewController(_:shapeFor:legIndex:)`.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor waypoints: [Waypoint], legIndex: Int) -> MGLShape?
    
    /**
     Called when the user taps to select a route on the navigation view controller’s map view.
     - parameter navigationViewController: The navigation view controller presenting the route that the user selected.
     - parameter route: The route on the map that the user selected.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSelect route: Route)
    
    /**
     Returns the center point of the user course view in screen coordinates relative to the map view.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, mapViewUserAnchorPoint mapView: NavigationMapView) -> CGPoint
    
    /**
     Allows the delegate to decide whether to ignore a location update.
     
     This method is called on every location update. By default, the navigation view controller ignores certain location updates that appear to be unreliable, as determined by the `CLLocation.isQualified` property.
     
     - parameter navigationViewController: The navigation view controller that discarded the location.
     - parameter location: The location that will be discarded.
     - returns: If `true`, the location is discarded and the `NavigationViewController` will not consider it. If `false`, the location will not be thrown out.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool
    
    /**
     Called to allow the delegate to customize the contents of the road name label that is displayed towards the bottom of the map view.
     
     This method is called on each location update. By default, the label displays the name of the road the user is currently traveling on.
     
     - parameter navigationViewController: The navigation view controller that will display the road name.
     - parameter location: The user’s current location.
     - returns: The road name to display in the label, or nil to hide the label.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, roadNameAt location: CLLocation) -> String?
}

public extension NavigationViewControllerDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .info)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return RouteController.DefaultBehavior.didArriveAtWaypoint
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return RouteController.DefaultBehavior.shouldRerouteFromLocation
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, willRerouteFrom location: CLLocation?) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToRerouteWith error: Error) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
    }

    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, mainRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }

    func navigationViewController(_ navigationViewController: NavigationViewController, mainRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }

    func navigationViewController(_ navigationViewController: NavigationViewController, alternativeRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }

    func navigationViewController(_ navigationViewController: NavigationViewController, alternateRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor routes: [Route]) -> MGLShape? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, simplifiedShapeFor route: Route) -> MGLShape? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor waypoints: [Waypoint], legIndex: Int) -> MGLShape? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, didSelect route: Route) {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, mapViewUserAnchorPoint mapView: NavigationMapView) -> CGPoint {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .info)
        return .zero
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return RouteController.DefaultBehavior.shouldDiscardLocation
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func navigationViewController(_ navigationViewController: NavigationViewController, roadNameAt location: CLLocation) -> String? {
        logUnimplemented(protocolType: NavigationViewControllerDelegate.self,  level: .debug)
        return nil
    }
}
