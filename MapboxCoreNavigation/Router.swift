import Foundation
import CoreLocation
import MapboxDirections

public typealias RouterDelegate = RouteControllerDelegate

@objc public protocol RouterDataSource {
    var location: CLLocation? { get }
    var locationProvider: NavigationLocationManager.Type { get }
}

@objc public protocol Router: class, CLLocationManagerDelegate {
    @objc unowned var dataSource: RouterDataSource { get }
    @objc var delegate: RouterDelegate? { get set }
    
//    var usesDefaultUserInterface: Bool { get set }
    var routeProgress: RouteProgress { get }
    var route: Route { get set }
//    func endNavigation(feedback: EndOfRouteFeedback?)

    @objc func userIsOnRoute(_ location: CLLocation) -> Bool
    @objc func reroute(from: CLLocation, along: RouteProgress)
    @objc var location: CLLocation? { get }
}
