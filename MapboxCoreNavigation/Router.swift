import Foundation
import CoreLocation
import MapboxDirections

public typealias RouterDelegate = RouteControllerDelegate

@objc public protocol Router: class, CLLocationManagerDelegate {
//    @objc var eventsManager: EventsManager! { get }
    @objc var locationManager: NavigationLocationManager! { get }
    @objc var delegate: RouterDelegate? { get set }
    @objc var tunnelIntersectionManager: TunnelIntersectionManager { get }
    
//    var usesDefaultUserInterface: Bool { get set }
    var routeProgress: RouteProgress { get }
    var route: Route { get set }
//    func endNavigation(feedback: EndOfRouteFeedback?)

    @objc func userIsOnRoute(_ location: CLLocation) -> Bool
    @objc func reroute(from: CLLocation, along: RouteProgress)
    @objc var location: CLLocation? { get }
}
