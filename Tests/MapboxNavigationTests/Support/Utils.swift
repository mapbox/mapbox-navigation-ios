import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxDirections
import CoreLocation
import TestHelper

var routeOptions: NavigationRouteOptions {
    let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
    let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
    return NavigationRouteOptions(waypoints: [from, to])
}
let jsonFileName = "routeWithInstructions"
let response = Fixture.routeResponse(from: jsonFileName, options: routeOptions)

extension UIViewController {
    func simulatateViewControllerPresented() {
        _ = view // load view
        viewWillAppear(false)
        viewDidAppear(false)
    }
}
