#if canImport(CarPlay)
import CarPlay
#if canImport(MapboxGeocoder)
import MapboxGeocoder
#endif
import Turf
import MapboxCoreNavigation
import MapboxDirections

/**
 `CarPlayManagerDelegate` is the main integration point for Mapbox CarPlay support.
 
 Implement this protocol and assign an instance to the `delegate` property of the shared instance of `CarPlayManager`.
 */
@available(iOS 12.0, *)
@objc(MBCarPlayManagerDelegate)
public protocol CarPlayManagerDelegate {
    
    /**
     Offers the delegate an opportunity to provide a customized list of leading bar buttons.
     
     These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the hierarchy of templates is adequately navigable.
     If this method is not implemented, or if nil is returned, an implementation of CPSearchTemplate will be provided which uses the Mapbox Geocoder.
     
     - parameter carPlayManager: The shared CarPlay manager.
     - parameter traitCollection: The trait collection of the view controller being shown in the CarPlay window.
     - parameter template: The template into which the returned bar buttons will be inserted.
     - parameter activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between multiple templates of the same kind, such as multiple `CPMapTemplate`s.
     - returns: An array of bar buttons to display on the leading side of the navigation bar while `template` is visible.
     */
    @objc(carPlayManager:leadingNavigationBarButtonsWithTraitCollection:inTemplate:forActivity:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]?
    
    /**
     Offers the delegate an opportunity to provide a customized list of trailing bar buttons.
     
     These buttons' tap handlers encapsulate the action to be taken, so it is up to the developer to ensure the hierarchy of templates is adequately navigable.
     
     - parameter carPlayManager: The shared CarPlay manager.
     - parameter traitCollection: The trait collection of the view controller being shown in the CarPlay window.
     - parameter template: The template into which the returned bar buttons will be inserted.
     - parameter activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between multiple templates of the same kind, such as multiple `CPMapTemplate`s.
     - returns: An array of bar buttons to display on the trailing side of the navigation bar while `template` is visible.
     */
    @objc(carPlayManager:trailingNavigationBarButtonsWithTraitCollection:inTemplate:forActivity:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]?
    
    /**
     Offers the delegate an opportunity to provide a customized list of buttons displayed on the map.
     
     These buttons handle the gestures on the map view, so it is up to the developer to ensure the map template is interactive.
     If this method is not implemented, or if nil is returned, a default set of zoom and pan buttons will be provided.
     
     - parameter carPlayManager: The shared CarPlay manager.
     - parameter traitCollection: The trait collection of the view controller being shown in the CarPlay window.
     - parameter template: The template into which the returned map buttons will be inserted.
     - parameter activity: What the user is currently doing on the CarPlay screen. Use this parameter to distinguish between multiple templates of the same kind, such as multiple `CPMapTemplate`s.
     - returns: An array of map buttons to display on the map while `template` is visible.
     */
    @objc(carPlayManager:mapButtonsCompatibleWithTraitCollection:inTemplate:forActivity:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPMapButton]?
    
    
    /**
     Offers the delegate an opportunity to provide an alternate navigation service, otherwise a default built-in MapboxNavigationService will be created and used.
     
     - parameter carPlayManager: The shared CarPlay manager.
     - parameter route: The route for which the returned route controller will manage location updates.
     - returns: A navigation service that manages location updates along `route`.
     */
    
    @objc(carPlayManager:navigationServiceAlongRoute:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, navigationServiceAlong route: Route) -> NavigationService
    
    /**
     Offers the delegate an opportunity to react to updates in the search text.
     
     - parameter carPlayManager: The shared CarPlay manager.
     - parameter searchTemplate: The search template currently accepting user input.
     - parameter searchText: The updated search text in `searchTemplate`.
     - parameter completionHandler: Called when the search is complete. Accepts a list of search results.
     
     - postcondition: You must call `completionHandler` within this method.
     */
    @objc(carPlayManager:searchTemplate:updatedSearchText:completionHandler:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void)
    
    /**
     Offers the delegate an opportunity to react to selection of a search result.
     
     - parameter carPlayManager: The shared CarPlay manager.
     - parameter searchTemplate: The search template currently accepting user input.
     - parameter item: The search result the user has selected.
     - parameter completionHandler: Called when the delegate is done responding to the selection.
     
     - postcondition: You must call `completionHandler` within this method.
     */
    @objc(carPlayManager:searchTemplate:selectedResult:completionHandler:)
    optional func carPlayManager(_ carPlayManager: CarPlayManager, searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void)
    
    /**
     Called when navigation begins so that the containing app can update accordingly.
     
     - parameter carPlayManager: The shared CarPlay manager.
     - parameter service: The navigation service that has begun managing location updates for a navigation session.
     */
    @objc(carPlayManager:didBeginNavigationWithNavigationService:)
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) -> ()
    
    /**
     Called when navigation ends so that the containing app can update accordingly.
     
     - parameter carPlayManager: The shared CarPlay manager.
     */
    @objc func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) -> ()
    
    /**
     Called when the carplay manager will disable the idle timer.
     
     Implementing this method will allow developers to change whether idle timer is disabled when carplay is connected and the vice-versa when disconnected.
     
     - parameter carPlayManager: The shared CarPlay manager.
     - returns: A Boolean value indicating whether to disable idle timer when carplay is connected and enable when disconnected.
     */
    @objc optional func carplayManagerShouldDisableIdleTimer(_ carPlayManager: CarPlayManager) -> Bool
}
#endif
