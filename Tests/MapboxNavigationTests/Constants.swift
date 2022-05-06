import XCTest
import TestHelper
import MapboxCoreNavigation
import MapboxDirections
import CoreLocation

struct ShieldImage {
    /// PNG at 3×
    let image: UIImage
    let baseURL: URL
}

extension ShieldImage {
    static let i280 = ShieldImage(image: Fixture.image(named: "i-280"),
                                  baseURL: URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/i-280")!)
    static let us101 = ShieldImage(image: Fixture.image(named: "us-101"),
                                   baseURL: URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/us-101")!)
    static let shieldDay = ShieldImage(image: Fixture.image(named: "shieldDay"),
                                       baseURL: URL(string: "https://api.mapbox.com/styles/v1")!)
    static let shieldNight = ShieldImage(image: Fixture.image(named: "shieldNight"),
                                         baseURL: URL(string: "https://api.mapbox.com/styles/v1")!)
}

var routeOptions: NavigationRouteOptions {
    let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
    let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
    return NavigationRouteOptions(waypoints: [from, to])
}

let jsonFileName = "routeWithInstructions"
let response = Fixture.routeResponse(from: jsonFileName, options: routeOptions)
