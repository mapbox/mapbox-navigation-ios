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
    var returnedManager: SimulatedLocationManager!

    override func makeManager(routeProgress: RouteProgress) -> SimulatedLocationManager {
        return returnedManager
    }
}
