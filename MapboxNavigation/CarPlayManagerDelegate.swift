#if canImport(CarPlay)
import CarPlay
import Turf
import MapboxCoreNavigation
import MapboxDirections

/**
 `CarPlayManagerDelegate` is the main integration point for Mapbox CarPlay support.
 
 Implement this protocol and assign an instance to the `delegate` property of the shared instance of `CarPlayManager`.
 
 If no delegate is set, a default built-in MapboxNavigationService will be created and used when a trip begins.
 */
@available(iOS 12.0, *)
public protocol CarPlayManagerDelegate: class, UnimplementedLogging {
    /**
     Offers the delegate an opportunity to provide a customized list of leading bar buttons at the root of the template stack for the given activity.
     
     These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the hierarchy of templates is adequately navigable.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter traitCollection: The trait collection of the view controller being shown in the CarPlay window.
     - parameter carPlayTemplate: The template into which the returned bar buttons will be inserted.
     - parameter activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between multiple templates of the same kind, such as multiple `CPMapTemplate`s.
     - returns: An array of bar buttons to display on the leading side of the navigation bar while `template` is visible.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in carPlayTemplate: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]?
    
    /**
     Offers the delegate an opportunity to provide a customized list of trailing bar buttons at the root of the template stack for the given activity.
     
     These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the hierarchy of templates is adequately navigable.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter traitCollection: The trait collection of the view controller being shown in the CarPlay window.
     - parameter carPlayTemplate: The template into which the returned bar buttons will be inserted.
     - parameter activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between multiple templates of the same kind, such as multiple `CPMapTemplate`s.
     - returns: An array of bar buttons to display on the trailing side of the navigation bar while `template` is visible.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in carPlayTemplate: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]?
   
    /**
     Offers the delegate an opportunity to provide a customized list of buttons displayed on the map.
     
     These buttons handle the gestures on the map view, so it is up to the developer to ensure the map template is interactive.
     If this method is not implemented, or if nil is returned, a default set of zoom and pan buttons declared in the `CarPlayMapViewController` will be provided.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter traitCollection: The trait collection of the view controller being shown in the CarPlay window.
     - parameter carPlayTemplate: The template into which the returned map buttons will be inserted.
     - parameter activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between multiple templates of the same kind, such as multiple `CPMapTemplate`s.
     - returns: An array of map buttons to display on the map while `template` is visible.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in carPlayTemplate: CPTemplate, for activity: CarPlayActivity) -> [CPMapButton]?
    
    /**
     Asks the delegate to provide a navigation service. In multi-screen applications this should be the same instance used to guide the user along the route on the phone.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter route: The route for which the returned route controller will manage location updates.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeOptions: the options that were specified for the route request.
     - parameter desiredSimulationMode: The desired simulation mode to use.
     - returns: A navigation service that manages location updates along `route`.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, navigationServiceAlong route: Route, routeIndex: Int, routeOptions: RouteOptions, desiredSimulationMode: SimulationMode) -> NavigationService
    
    /**
     Offers the delegate an opportunity to react to updates in the search text.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter searchTemplate: The search template currently accepting user input.
     - parameter searchText: The updated search text in `searchTemplate`.
     - parameter completionHandler: Called when the search is complete. Accepts a list of search results.
     
     - postcondition: You must call `completionHandler` within this method.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void)
    
    /**
     Offers the delegate an opportunity to react to selection of a search result.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter searchTemplate: The search template currently accepting user input.
     - parameter item: The search result the user has selected.
     - parameter completionHandler: Called when the delegate is done responding to the selection.
     
     - postcondition: You must call `completionHandler` within this method.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void)
    
    /**
     Called when the CarPlay manager fails to fetch a route.
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter waypoints: the waypoints for which a route could not be retrieved.
     - parameter options: The route options that were attached to the route request.
     - parameter error: The error returned from the directions API.
     - returns: Optionally, a `CPNavigationAlert` to present to the user. If this method returns an alert, the CarPlay manager will transition back to the map template and display the alert. If it returns `nil`, the CarPlay manager will do nothing.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, didFailToFetchRouteBetween waypoints: [Waypoint]?, options: RouteOptions, error: DirectionsError) -> CPNavigationAlert?
    
    /**
     Offers the delegate the opportunity to customize a trip before it is presented to the user to preview.
     
     To customize the destination’s title, which is displayed when a route is selected, set the `MKMapItem.name` property of the `CPTrip.destination` property. To add a subtitle, create a new `MKMapItem` whose `MKPlacemark` has the `Street` key in its address dictionary.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter trip: The trip that will be previewed.
     - returns: The actual trip to be previewed. This can be the same trip or a new/alternate trip if desired.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, willPreview trip: CPTrip) -> (CPTrip)

    /**
     Offers the delegate the opportunity to customize a trip preview text configuration for a given trip.

     - parameter carPlayManager: The CarPlay manager instance.
     - parameter trip: The trip that will be previewed.
     - parameter previewTextConfiguration: The trip preview text configuration that will be presented alongside the trip.
     - returns: The actual preview text configuration to be presented alongside the trip.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, willPreview trip: CPTrip, with previewTextConfiguration: CPTripPreviewTextConfiguration) -> (CPTripPreviewTextConfiguration)

    /**
     Offers the delegate the opportunity to react to selection of a trip. Certain trips may have alternate route(s).
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter trip: The trip to begin navigating along.
     - parameter routeChoice: The possible route for the chosen trip.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) -> ()
    
    /**
     Called when navigation begins so that the containing app can update accordingly.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - parameter service: The navigation service that has begun managing location updates for a navigation session.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) -> ()
    
    /**
     Called when navigation ends so that the containing app can update accordingly.
     
     - parameter carPlayManager: The CarPlay manager instance.
     */
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) -> ()
    
    /**
     Called when the carplay manager will disable the idle timer.
     
     Implementing this method will allow developers to change whether idle timer is disabled when carplay is connected and the vice-versa when disconnected.
     
     - parameter carPlayManager: The CarPlay manager instance.
     - returns: A Boolean value indicating whether to disable idle timer when carplay is connected and enable when disconnected.
     */
    func carplayManagerShouldDisableIdleTimer(_ carPlayManager: CarPlayManager) -> Bool
}

@available(iOS 12.0, *)
public extension CarPlayManagerDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in carPlayTemplate: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in carPlayTemplate: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in carPlayTemplate: CPTemplate, for activity: CarPlayActivity) -> [CPMapButton]? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, didFailToFetchRouteBetween waypoints: [Waypoint]?, options: RouteOptions, error: DirectionsError) -> CPNavigationAlert? {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, willPreview trip: CPTrip) -> (CPTrip) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
        return trip
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, willPreview trip: CPTrip, with previewTextConfiguration: CPTripPreviewTextConfiguration) -> (CPTripPreviewTextConfiguration) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
        return previewTextConfiguration
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carplayManagerShouldDisableIdleTimer(_ carPlayManager: CarPlayManager) -> Bool {
        logUnimplemented(protocolType: CarPlayManagerDelegate.self,  level: .debug)
        return false
    }
}
#endif
