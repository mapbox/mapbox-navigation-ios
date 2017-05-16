import Foundation
import MapboxDirections
import CoreLocation

extension Directions {
    
    public func synchronousRoute(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> Route? {
        let options = RouteOptions(coordinates: [origin, destination], profileIdentifier: .automobile)
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = .automobileAvoidingTraffic
        
        let semaphore = DispatchSemaphore(value: 0)
        var route: Route?
        
        _ = calculate(options) { (waypoints, routes, error) in
            if let r = routes?.first {
                route = r
            }
            semaphore.signal()
        }
        
        if semaphore.wait(timeout: DispatchTime.now() + .seconds(5)) == .timedOut {
            return route
        }
        
        return route
    }
    
}
