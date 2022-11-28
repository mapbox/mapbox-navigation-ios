import CoreLocation
import MapboxDirections
@testable import MapboxCoreNavigation

final class SimulatedLocationManagerSpy: SimulatedLocationManager {
    var startUpdatingLocationCalled = false
    var startUpdatingHeadingCalled = false
    var stopUpdatingLocationCalled = false
    var stopUpdatingHeadingCalled = false

    override func startUpdatingLocation() {
        startUpdatingLocationCalled = true
    }

    override func startUpdatingHeading() {
        startUpdatingHeadingCalled = true
    }

    override func stopUpdatingLocation() {
        stopUpdatingLocationCalled = true
    }

    override func stopUpdatingHeading() {
        stopUpdatingHeadingCalled = true
    }

    func reset() {
        startUpdatingLocationCalled = false
        startUpdatingHeadingCalled = false
        stopUpdatingLocationCalled = false
        stopUpdatingHeadingCalled = false
    }
}

final class SimulatedLocationManagerFactorySpy: SimulatedLocationManagerFactory {
    var returnedManager: SimulatedLocationManagerSpy

    override init() {
        let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let routeOptions = NavigationRouteOptions(waypoints: [from, to])
        let route = Fixture.route(from: "routeWithInstructions", options: routeOptions)
        returnedManager = SimulatedLocationManagerSpy(route: route, currentDistance: 100, currentSpeed: 20)
    }

    override func makeManager(routeProgress: RouteProgress) -> SimulatedLocationManager {
        return returnedManager
    }
}
