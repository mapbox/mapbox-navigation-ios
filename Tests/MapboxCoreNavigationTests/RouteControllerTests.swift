import XCTest
import Turf
import MapboxDirections
import CoreLocation
@testable import MapboxCoreNavigation
import TestHelper
import MapboxNavigationNative

class RouteControllerTests: TestCase {
    var replayManager: ReplayLocationManager?

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        replayManager = nil
        NavigationRouter.__testRoutesStub = nil
        super.tearDown()
    }
    
    func testRouteSnappingOvershooting() {
        let options = NavigationMatchOptions(coordinates: [
            .init(latitude: 59.337928, longitude: 18.076841),
            .init(latitude: 59.33865, longitude: 18.074935),
        ])
        let routeResponse = Fixture.routeResponseFromMatches(at: "sthlm-double-back", options: options)
        let locations = Array<CLLocation>.locations(from: "sthlm-double-back-replay").shiftedToPresent()
        let locationManager = ReplayLocationManager(locations: locations)
        replayManager = locationManager
        let equivalentRouteOptions = NavigationRouteOptions(navigationMatchOptions: options)
        let routeController = RouteController(alongRouteAtIndex: 0, in: routeResponse, options: equivalentRouteOptions, dataSource: self)
        locationManager.delegate = routeController
        let routerDelegateSpy = RouterDelegateSpy()
        routeController.delegate = routerDelegateSpy

        var actualCoordinates = [CLLocationCoordinate2D]()
        routerDelegateSpy.onShouldDiscard = { location in
            actualCoordinates.append(location.coordinate)
            return false
        }
        let expectedTestCoordinatesCount = locationManager.locations.count
        expectation(description: "All coordinates processed") {
            actualCoordinates.count == expectedTestCoordinatesCount
        }

        let replayFinished = expectation(description: "Replay Finished")
        locationManager.replayCompletionHandler = { _ in
            replayFinished.fulfill()
            return false
        }

        let speedMultiplier: TimeInterval = 100
        locationManager.speedMultiplier = speedMultiplier
        locationManager.startUpdatingLocation()

        waitForExpectations(timeout: locationManager.expectedReplayTime, handler: nil)

        let expectedCoordinates = locations.map(\.coordinate)
        XCTAssertEqual(expectedCoordinates, actualCoordinates)
    }

    func testRerouteAfterArrival() {
        let origin = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let destination = CLLocationCoordinate2D(latitude: 0.01, longitude: 0.01)

        let routeResponse = Fixture.route(between: origin, and: destination).response

        let overshootingDestination = CLLocationCoordinate2D(latitude: 0.02, longitude: 0.02)
        let replyLocations = Fixture.generateCoordinates(between: origin, and: overshootingDestination, count: 100).map {
            CLLocation(coordinate: $0)
        }.shiftedToPresent()

        let navOptions = NavigationRouteOptions(coordinates: [origin, destination])
        let routeController = RouteController(alongRouteAtIndex: 0,
                                              in: routeResponse,
                                              options: navOptions,
                                              routingSource: .offline,
                                              dataSource: self)

        let routerDelegateSpy = RouterDelegateSpy()
        routeController.delegate = routerDelegateSpy

        let locationManager = ReplayLocationManager(locations: replyLocations)
        locationManager.startDate = Date()
        locationManager.delegate = routeController

        let shouldRerouteCalled = expectation(description: "Should reroute called")
        shouldRerouteCalled.assertForOverFulfill = false
        
        let shouldPreventReroutesCalled = expectation(description: "Should prevent reroutes called")
        shouldPreventReroutesCalled.assertForOverFulfill = false
        
        let didRerouteCalled = expectation(description: "Did reroute called")
        didRerouteCalled.assertForOverFulfill = false
        
        let calculateRouteCalled = expectation(description: "Calculate route called")
        calculateRouteCalled.assertForOverFulfill = false
        
        routerDelegateSpy.onShouldPreventReroutesWhenArrivingAt = { _ in
            shouldPreventReroutesCalled.fulfill()
            return false
        }
        
        routerDelegateSpy.onShouldRerouteFrom = { _ in
            shouldRerouteCalled.fulfill()
            return true
        }
        
        routerDelegateSpy.onDidRerouteAlong = { _ in
            didRerouteCalled.fulfill()
        }
        
        NavigationRouter.__testRoutesStub = { (options, completionHandler) in
            calculateRouteCalled.fulfill()
            let currentCoordinate = locationManager.location!.coordinate
            
            let originWaypoint = Waypoint(coordinate: currentCoordinate)
            let destinationWaypoint = Waypoint(coordinate: destination)
            
            let waypoints = [
                originWaypoint,
                destinationWaypoint
            ]
            
            completionHandler(Directions.Session(options, DirectionsCredentials()),
                              .success(RouteResponse(httpResponse: nil,
                                                     identifier: nil,
                                                     routes: [Fixture.route(between: currentCoordinate,
                                                                            and: destination).route],
                                                     waypoints: waypoints,
                                                     options: .route(options),
                                                     credentials: .mocked)))
            return 0
        }

        let replayFinished = expectation(description: "Replay Finished")
        locationManager.speedMultiplier = 50
        locationManager.replayCompletionHandler = { _ in
            replayFinished.fulfill()
            return false
        }
        locationManager.startUpdatingLocation()
        wait(for: [replayFinished], timeout: locationManager.expectedReplayTime)

        waitForExpectations(timeout: 1, handler: nil)
    }
}

extension RouteControllerTests: RouterDataSource {
    var location: CLLocation? {
        return replayManager?.location
    }
    
    var locationManagerType: NavigationLocationManager.Type {
        return NavigationLocationManager.self
    }
}
