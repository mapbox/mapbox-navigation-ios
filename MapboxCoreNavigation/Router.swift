import Foundation
import CoreLocation
import MapboxDirections

@objc (MBRouterDataSource)
public protocol RouterDataSource {
    var location: CLLocation? { get }
    var locationProvider: NavigationLocationManager.Type { get }
}

@objc public protocol Router: class, CLLocationManagerDelegate {
    
    /**
     The route controller’s associated location manager.
     */
    @objc unowned var dataSource: RouterDataSource { get }
    
    /**
     The route controller’s delegate.
     */
    @objc var delegate: RouterDelegate? { get set }
    
    /**
     Intializes a new `RouteController`.
     
     - parameter route: The route to follow.
     - parameter directions: The Directions object that created `route`.
     - parameter source: The data source for the RouteController.
     */
    @objc(initWithRoute:directions:dataSource:)
    init(along route: Route, directions: Directions, dataSource source: RouterDataSource)
    
    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    @objc var routeProgress: RouteProgress { get }
    
    @objc var route: Route { get set }
    
    /**
     Given a users current location, returns a Boolean whether they are currently on the route.
     
     If the user is not on the route, they should be rerouted.
     */
    @objc func userIsOnRoute(_ location: CLLocation) -> Bool
    @objc func reroute(from: CLLocation, along: RouteProgress)
    
    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw or nil.
     */
    @objc var location: CLLocation? { get }
    
    /**
     Advances the leg index.
     
     This is a convienence method provided to advance the leg index of any given router without having to worry about the internal data structure of the router.
     */
    @objc(advanceLegIndexWithLocation:)
    func advanceLegIndex(location: CLLocation)
    
    @objc optional func enableLocationRecording()
    @objc optional func disableLocationRecording()
    @objc optional func locationHistory() -> String
}
