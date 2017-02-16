import Foundation
import Mapbox
import MapboxDirections
import UIKit

extension RouteOptions {
    class func preferredOptions(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, heading: CLLocationDirection? = nil, profileIdentifier: String? = nil) -> RouteOptions {
        let options = RouteOptions(coordinates: [origin, destination])
        
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = profileIdentifier ?? MBDirectionsProfileIdentifierAutomobileAvoidingTraffic
        
        if let heading = heading, heading >= 0, let firstWaypoint = options.waypoints.first {
            firstWaypoint.heading = heading
            firstWaypoint.headingAccuracy = 90
        }
        
        return options
    }
}
