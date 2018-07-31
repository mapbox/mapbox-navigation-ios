import Foundation
import CoreLocation
import MapboxDirections

@objc public protocol Router: class, CLLocationManagerDelegate {
    @objc var eventsManager: EventsManager! { get }
    @objc var locationManager: NavigationLocationManager! { get }
    
    var usesDefaultUserInterface: Bool { get }
    var routeProgress: RouteProgress { get }
    func endNavigation(feedback: EndOfRouteFeedback?)

    @objc var location: CLLocation? { get }
}
