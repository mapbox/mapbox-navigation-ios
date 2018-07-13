import Foundation
import CoreLocation
import MapboxDirections

@objc public protocol Router: class, CLLocationManagerDelegate {
    @objc var eventsManager: EventsManager! { get } //todo: remove this
    @objc var locationManager: NavigationLocationManager! { get } //todo: also remove this
    
    var usesDefaultUserInterface: Bool { get }
    var routeProgress: RouteProgress { get } // TODO: Protocolize RouteProgress

    func locationIsOnRoute(_ location: CLLocation) -> Bool //userIsOnRoute(_ location: CLLocation)
    
    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw.
     - seeAlso: snappedLocation, rawLocation
     */
    @objc var location: CLLocation? { get }
}
