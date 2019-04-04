import Foundation
import MapboxDirections

/**
 The `NavigationViewControllerDelegate` protocol provides methods for configuring the map view shown by a `NavigationViewController` and responding to the cancellation of a navigation session.
 */
@objc(MBNavigationViewControllerDelegate)
public protocol NavigationViewControllerDelegate: VisualInstructionDelegate {
    /**
     Called when the navigation view controller is dismissed, such as when the user ends a trip.
     
     - parameter navigationViewController: The navigation view controller that was dismissed.
     - parameter canceled: True if the user dismissed the navigation view controller by tapping the Cancel button; false if the navigation view controller dismissed by some other means.
     */
    @objc optional func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool)
    
    /**
     Called as the user approaches a waypoint.
     
     This message is sent, once per progress update, as the user is approaching a waypoint. You can use this to cue UI, to do network pre-loading, etc.
     - parameter navigationViewController: The Navigation VC that is detecting the users' approach.
     - parameter waypoint: The waypoint that the service is arriving at.
     - parameter remainingTimeInterval: The estimated number of seconds until arrival.
     - parameter distance: The current distance from the waypoint, in meters.
     - note: This method will likely be called several times as you approach a destination. To respond to the user’s arrival only once, your delegate can define a property that keeps track of whether this method has already been called for the given waypoint.
     */
    @objc(navigationViewController:willArriveAtWaypoint:after:distance:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance)
    
    /**
     Called when the user arrives at the destination waypoint for a route leg.
     
     This method is called when the navigation view controller arrives at the waypoint. You can implement this method to prevent the navigation view controller from automatically advancing to the next leg. For example, you can and show an interstitial sheet upon arrival and pause navigation by returning `false`, then continue the route when the user dismisses the sheet. If this method is unimplemented, the navigation view controller automatically advances to the next leg when arriving at a waypoint.
     
     - postcondition: If you return `false` within this method, you must manually advance to the next leg: obtain the value of the `navigationService` and its `NavigationService.routeProgress` property, then increment the `RouteProgress.legIndex` property.
     - parameter navigationViewController: The navigation view controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the user has arrived at.
     - returns: True to automatically advance to the next leg, or false to remain on the now completed leg.
     */
    @objc(navigationViewController:didArriveAtWaypoint:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool
    
    /**
     Returns whether the navigation view controller should be allowed to calculate a new route.
     
     If implemented, this method is called as soon as the navigation view controller detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `navigationViewController(_:willRerouteFrom:)` will be called immediately afterwards.
     
     - parameter navigationViewController: The navigation view controller that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the navigation view controller to calculate a new route; false to keep tracking the current route.
     */
    @objc(navigationViewController:shouldRerouteFromLocation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool
    
    /**
     Called immediately before the navigation view controller calculates a new route.
     
     This method is called after `navigationViewController(_:shouldRerouteFrom:)` is called, simultaneously with the `RouteControllerWillReroute` notification being posted, and before `navigationViewController(_:didRerouteAlong:)` is called.
     
     - parameter navigationViewController: The navigation view controller that will calculate a new route.
     - parameter location: The user’s current location.
     */
    @objc(navigationViewController:willRerouteFromLocation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, willRerouteFrom location: CLLocation?)
    
    /**
     Called immediately after the navigation view controller receives a new route.
     
     This method is called after `navigationViewController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidReroute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has calculated a new route.
     - parameter route: The new route.
     */
    @objc(navigationViewController:didRerouteAlongRoute:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route)
    
    /**
     Called when the navigation view controller fails to receive a new route.
     
     This method is called after `navigationViewController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidFailToReroute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    @objc(navigationViewController:didFailToRerouteWithError:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, didFailToRerouteWith error: Error)
    
    /**
     Returns an `MGLStyleLayer` that determines the appearance of the route line.
     
     If this method is unimplemented, the navigation view controller’s map view draws the route line using an `MGLLineStyleLayer`.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLStyleLayer` that determines the appearance of the route line’s casing.
     
     If this method is unimplemented, the navigation view controller’s map view draws the route line’s casing using an `MGLLineStyleLayer` whose width is greater than that of the style layer returned by `navigationViewController(_:routeStyleLayerWithIdentifier:source:)`.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLShape` that represents the path of the route line.
     
     If this method is unimplemented, the navigation view controller’s map view represents the route line using an `MGLPolylineFeature` based on `route`’s `coordinates` property.
     */
    @objc(navigationViewController:shapeForRoutes:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor routes: [Route]) -> MGLShape?
    
    /**
     Returns an `MGLShape` that represents the path of the route line’s casing.
     
     If this method is unimplemented, the navigation view controller’s map view represents the route line’s casing using an `MGLPolylineFeature` identical to the one returned by `navigationViewController(_:shapeFor:)`.
     */
    @objc(navigationViewController:simplifiedShapeForRoute:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, simplifiedShapeFor route: Route) -> MGLShape?
    
    /*
     Returns an `MGLStyleLayer` that marks the location of each destination along the route when there are multiple destinations. The returned layer is added to the map below the layer returned by `navigationViewController(_:waypointSymbolStyleLayerWithIdentifier:source:)`.
     
     If this method is unimplemented, the navigation view controller’s map view marks each destination waypoint with a circle.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /*
     Returns an `MGLStyleLayer` that places an identifying symbol on each destination along the route when there are multiple destinations. The returned layer is added to the map above the layer returned by `navigationViewController(_:waypointStyleLayerWithIdentifier:source:)`.
     
     If this method is unimplemented, the navigation view controller’s map view labels each destination waypoint with a number, starting with 1 at the first destination, 2 at the second destination, and so on.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLShape` that represents the destination waypoints along the route (that is, excluding the origin).
     
     If this method is unimplemented, the navigation map view represents the route waypoints using `navigationViewController(_:shapeFor:legIndex:)`.
     */
    @objc(navigationViewController:shapeForWaypoints:legIndex:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor waypoints: [Waypoint], legIndex: Int) -> MGLShape?
    
    /**
     Called when the user taps to select a route on the navigation view controller’s map view.
     - parameter navigationViewController: The navigation view controller presenting the route that the user selected.
     - parameter route: The route on the map that the user selected.
     */
    @objc(navigationViewController:didSelectRoute:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, didSelect route: Route)
    
    /**
     Returns the center point of the user course view in screen coordinates relative to the map view.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, mapViewUserAnchorPoint mapView: NavigationMapView) -> CGPoint
    
    /**
     Allows the delegate to decide whether to ignore a location update.
     
     This method is called on every location update. By default, the navigation view controller ignores certain location updates that appear to be unreliable, as determined by the `CLLocation.isQualified` property.
     
     - parameter navigationViewController: The navigation view controller that discarded the location.
     - parameter location: The location that will be discarded.
     - returns: If `true`, the location is discarded and the `NavigationViewController` will not consider it. If `false`, the location will not be thrown out.
     */
    @objc(navigationViewController:shouldDiscardLocation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool
    
    /**
     Called to allow the delegate to customize the contents of the road name label that is displayed towards the bottom of the map view.
     
     This method is called on each location update. By default, the label displays the name of the road the user is currently traveling on.
     
     - parameter navigationViewController: The navigation view controller that will display the road name.
     - parameter location: The user’s current location.
     - returns: The road name to display in the label, or nil to hide the label.
     */
    @objc(navigationViewController:roadNameAtLocation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, roadNameAt location: CLLocation) -> String?
    
    
    //MARK: Obsolete
    
    @available(*, obsoleted: 0.1, message: "Use MGLMapViewDelegate.mapView(_:imageFor:) instead.")
    @objc(navigationViewController:imageForAnnotation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage?
    
    @available(*, obsoleted: 0.1, message: "Use MGLMapViewDelegate.mapView(_:viewFor:) instead.")
    @objc(navigationViewController:viewForAnnotation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, viewFor annotation: MGLAnnotation) -> MGLAnnotationView?
}

