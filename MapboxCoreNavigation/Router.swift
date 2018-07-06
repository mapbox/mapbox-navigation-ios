import Foundation
import CoreLocation
import MapboxDirections

@objc public protocol Router: class {
    @objc var eventsManager: EventsManager! { get }
    @objc var locationManager: NavigationLocationManager! { get }
    @objc optional func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    
    var usesDefaultUserInterface: Bool { get }
    var routeProgress: RouteProgress { get } // TODO: Protocolize RouteProgress

    func locationIsOnRoute(_ location: CLLocation) -> Bool //userIsOnRoute(_ location: CLLocation)
    
    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw.
     - seeAlso: snappedLocation, rawLocation
     */
    @objc var location: CLLocation? { get }
}
