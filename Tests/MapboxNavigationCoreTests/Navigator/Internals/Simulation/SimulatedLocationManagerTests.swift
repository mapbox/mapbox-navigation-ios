import _MapboxNavigationTestHelpers
import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import Turf
import XCTest

final class SimulatedLocationManagerTests: BaseTestCase {
    fileprivate var locationDelegate: NavigationLocationManagerDelegateSpy!
    var locationManager: SimulatedLocationManager!
    var initialShape: LineString!
    var progress: RouteProgress!
    var route: Route!
    var customQueue: DispatchQueue!

    var coordinates: [CLLocationCoordinate2D] = [
        .init(latitude: 59.337928, longitude: 18.076841),
        .init(latitude: 59.337661, longitude: 18.075897),
        .init(latitude: 59.337129, longitude: 18.075478),
        .init(latitude: 59.336866, longitude: 18.075273),
        .init(latitude: 59.336623, longitude: 18.075806),
        .init(latitude: 59.336391, longitude: 18.076943),
        .init(latitude: 59.338731, longitude: 18.079343),
        .init(latitude: 59.339058, longitude: 18.07774),
        .init(latitude: 59.338901, longitude: 18.076929),
        .init(latitude: 59.338333, longitude: 18.076467),
        .init(latitude: 59.338156, longitude: 18.075723),
        .init(latitude: 59.338311, longitude: 18.074968),
        .init(latitude: 59.33865, longitude: 18.074935),
    ]

    override func setUp() async throws {
        try await super.setUp()

        let initialLocation = CLLocation(coordinate: coordinates[0])
        initialShape = LineString(coordinates)
        route = Route.mock(shape: initialShape)
        progress = await RouteProgress.mock(navigationRoutes: .mock(mainRoute: .mock(route: route)))
        customQueue = DispatchQueue(label: "test.queue")
        locationManager = await SimulatedLocationManager(
            initialLocation: initialLocation,
            queue: customQueue
        )
        locationDelegate = NavigationLocationManagerDelegateSpy()
        locationManager.locationDelegate = locationDelegate
    }

    @MainActor
    func testSimulateCoordinatesFromTheStart() {
        locationManager.progressDidChange(progress)
        customQueue.sync {
            // to make sure the queue tasks are executed
        }
        while locationManager.currentDistance < initialShape.distance() ?? 0 {
            customQueue.sync { [weak self] in
                self?.locationManager.tick()
            }
        }
        let testCoordinates = locationDelegate.passedLocations.map { $0.coordinate }

        XCTAssertEqual(testCoordinates.last, coordinates.last)
        let testDistance = LineString(testCoordinates).distance()!
        XCTAssertEqual(testDistance, initialShape.distance()!, accuracy: 50)
    }

    @MainActor
    func testSimulateCoordinatesFromTheMidLocation() {
        locationManager.location = CLLocation(coordinate: coordinates[4])
        locationManager.progressDidChange(progress)
        customQueue.sync {
            // to make sure the queue tasks are executed
        }
        while locationManager.currentDistance < initialShape.distance() ?? 0 {
            customQueue.sync { [weak self] in
                self?.locationManager.tick()
            }
        }
        let testCoordinates = locationDelegate.passedLocations.map { $0.coordinate }

        XCTAssertEqual(testCoordinates.last, coordinates.last)
        let trimmedCoordinates = Array(coordinates.suffix(from: 4))
        let expectedShape = LineString(trimmedCoordinates)
        let testDistance = LineString(testCoordinates).distance()!
        XCTAssertEqual(testDistance, expectedShape.distance()!, accuracy: 50)
    }

    @MainActor
    func testUpdateRouteProgress() async {
        locationManager.progressDidChange(progress)
        customQueue.sync {}

        let shape = LineString([coordinates[3]])
        let newRoute = Route.mock(shape: shape)
        let newProgress = await RouteProgress.mock(navigationRoutes: .mock(mainRoute: .mock(route: newRoute)))
        locationManager.didReroute(progress: newProgress)
        customQueue.sync {}
        XCTAssertEqual(locationManager.routeProgress, newProgress)
        XCTAssertEqual(locationManager.remainingRouteShape, shape)
    }

    func testHandlesRouteChangeFromProgressUpdates() async {
        locationManager.progressDidChange(progress)
        customQueue.sync {}

        let shape = LineString(Array(coordinates.suffix(from: 4)))
        let newRoute = Route.mock(shape: shape, distance: 200)
        let newProgress = await RouteProgress.mock(navigationRoutes: .mock(mainRoute: .mock(route: newRoute)))

        locationManager.progressDidChange(newProgress)
        customQueue.sync {}

        let trimmedShape = LineString(Array(coordinates.suffix(from: 9)))
        XCTAssertEqual(locationManager.routeProgress, newProgress)
        XCTAssertEqual(locationManager.remainingRouteShape, trimmedShape)
    }

    @MainActor
    func testUpdateProgressDuringNavigation() async {
        locationManager.progressDidChange(progress)
        let lineString = LineString([
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 2, longitude: 2),
        ])
        let newRoute = Route.mock(shape: lineString)
        let newProgress = await RouteProgress.mock(navigationRoutes: .mock(mainRoute: .mock(route: newRoute)))
        locationManager.didReroute(progress: newProgress)
        customQueue.sync {}
        for _ in 0..<100 {
            customQueue.async { [weak self] in
                self?.locationManager.tick()
            }
            locationManager.progressDidChange(nil)
            customQueue.async { [weak self] in
                self?.locationManager.tick()
            }
            locationManager.progressDidChange(newProgress)
        }
        XCTAssertEqual(locationManager.routeProgress, newProgress)
    }
}

private final class NavigationLocationManagerDelegateSpy: NSObject, NavigationLocationManagerDelegate {
    var passedLocations = [CLLocation]()

    func navigationLocationManager(
        _ locationManager: NavigationLocationManager,
        didReceiveNewLocation location: CLLocation
    ) {
        passedLocations.append(location)
    }
}
