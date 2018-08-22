import Foundation
import CoreLocation
import MapboxDirections

@objc (MBRouterDataSource)
public protocol RouterDataSource {
    var location: CLLocation? { get }
    var locationProvider: NavigationLocationManager.Type { get }
}

@objc public protocol Router: class, CLLocationManagerDelegate {
    @objc unowned var dataSource: RouterDataSource { get }
    @objc var delegate: RouterDelegate? { get set }
    
    @objc(initWithRoute:directions:locationManager:)
    init(along route: Route, directions: Directions, dataSource source: RouterDataSource)
    
    @objc var routeProgress: RouteProgress { get }
    @objc var route: Route { get set }
    @objc func userIsOnRoute(_ location: CLLocation) -> Bool
    @objc func reroute(from: CLLocation, along: RouteProgress)
    @objc var location: CLLocation? { get }
}
