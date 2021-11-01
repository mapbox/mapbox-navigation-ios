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
        MapboxRoutingProvider.__testRoutesStub = nil
        super.tearDown()
    }
    
    // FIXME: In case if `testRerouteAfterArrival` is called before `testRouteSnappingOvershooting`,
    // precondition will be triggered in `RouteController.updateIndexes(status:progress:)`, which will lead
    // to a test failure.
    func disabled_testRouteSnappingOvershooting() {
        let options = NavigationMatchOptions(coordinates: [
            .init(latitude: 59.337928, longitude: 18.076841),
            .init(latitude: 59.33865, longitude: 18.074935),
        ])
        let routeResponse = Fixture.routeResponseFromMatches(at: "sthlm-double-back", options: options)
        let locations = Array<CLLocation>.locations(from: "sthlm-double-back-replay").shiftedToPresent()
        let locationManager = ReplayLocationManager(locations: locations)
        replayManager = locationManager
        let equivalentRouteOptions = NavigationRouteOptions(navigationMatchOptions: options)
        let routeController = RouteController(alongRouteAtIndex: 0, in: routeResponse, options: equivalentRouteOptions, routingProvider: MapboxRoutingProvider(.offline), dataSource: self)
        locationManager.delegate = routeController
        let routerDelegateSpy = RouterDelegateSpy()
        routeController.delegate = routerDelegateSpy
        routeController.reroutesProactively = false

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
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.750384, longitude: -122.387487),
            CLLocationCoordinate2D(latitude: 37.764343, longitude: -122.388664),
        ]
        
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        let route = Fixture.route(from: "route-for-off-route", options: navigationRouteOptions)
        var replayLocations = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
        let routeResponse = RouteResponse(httpResponse: nil,
                                          routes: [route],
                                          options: .route(.init(locations: replayLocations, profileIdentifier: nil)),
                                          credentials: .mocked)
        
        guard let lastReplayLocation = replayLocations.last else {
            XCTFail("First and last route locations should be valid.")
            return
        }
        
        let routeController = RouteController(alongRouteAtIndex: 0,
                                              in: routeResponse,
                                              options: navigationRouteOptions,
                                              routingProvider: MapboxRoutingProvider(.offline),
                                              dataSource: self)

        let routerDelegateSpy = RouterDelegateSpy()
        routeController.delegate = routerDelegateSpy
        
        // Generate additional coordinates right after the last coordinate on the original route
        // to simulate off route navigation.
        let overshootingDestination = CLLocationCoordinate2D(latitude: 37.775395, longitude: -122.389875)
        let offRouteReplayLocation = Fixture.generateCoordinates(between: lastReplayLocation.coordinate,
                                                                 and: overshootingDestination,
                                                                 count: 100).map {
            CLLocation(coordinate: $0)
        }.shiftedToPresent()
        
        replayLocations.append(contentsOf: offRouteReplayLocation)
        
        let locationManager = ReplayLocationManager(locations: replayLocations)
        locationManager.startDate = Date()
        locationManager.delegate = routeController

        let shouldRerouteCalled = expectation(description: "Reroute event should be called.")
        shouldRerouteCalled.assertForOverFulfill = false
        
        routerDelegateSpy.onShouldRerouteFrom = { _ in
            shouldRerouteCalled.fulfill()
            return true
        }
        
        let shouldPreventReroutesCalled = expectation(description: "Prevent reroutes event should be called.")
        shouldPreventReroutesCalled.assertForOverFulfill = false
        
        routerDelegateSpy.onShouldPreventReroutesWhenArrivingAt = { _ in
            shouldPreventReroutesCalled.fulfill()
            return false
        }

        let didRerouteCalled = expectation(description: "Did reroute event should be called.")
        didRerouteCalled.assertForOverFulfill = false
        
        routerDelegateSpy.onDidRerouteAlong = { _ in
            didRerouteCalled.fulfill()
        }
        
        let calculateRouteCalled = expectation(description: "Calculate route event should called.")
        calculateRouteCalled.assertForOverFulfill = false
        
        MapboxRoutingProvider.__testRoutesStub = { (options, completionHandler) in
            DispatchQueue.main.async {
                completionHandler(Directions.Session(options, .mocked),
                                  .success(routeResponse))
            }
            calculateRouteCalled.fulfill()
            return nil
        }

        let replayFinished = expectation(description: "Replay should be successfully finished.")
        locationManager.speedMultiplier = 50
        locationManager.replayCompletionHandler = { _ in
            replayFinished.fulfill()
            return false
        }
        locationManager.startUpdatingLocation()
        wait(for: [replayFinished], timeout: locationManager.expectedReplayTime)

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRerouteDangerousManeuverOverride() {
        let origin = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let destination = CLLocationCoordinate2D(latitude: 0.001, longitude: 0.001)

        let routeResponse = Fixture.route(between: origin, and: destination).response
        let routeCoordinates = Fixture.generateCoordinates(between: origin, and: destination, count: 10)

        let overshootingDestination = CLLocationCoordinate2D(latitude: 0.002, longitude: 0.002)
        let replyLocations = Fixture.generateCoordinates(between: origin, and: overshootingDestination, count: 11).map {
            CLLocation(coordinate: $0)
        }.shiftedToPresent()

        let directions = DirectionsSpy()

        let navOptions = NavigationRouteOptions(coordinates: routeCoordinates)
        navOptions.initialManeuverAvoidanceRadius = 100
        
        let routeController = RouteController(alongRouteAtIndex: 0,
                                              in: routeResponse,
                                              options: navOptions,
                                              directions: directions,
                                              dataSource: self)

        let routerDelegateSpy = RouterDelegateSpy()
        routeController.delegate = routerDelegateSpy

        let locationManager = ReplayLocationManager(locations: replyLocations)
        locationManager.startDate = Date()
        locationManager.delegate = routeController

        routerDelegateSpy.onManeuverOffsetWhenRerouting = {
            return .radius(500)
        }
        
        let calculateRouteCalled = expectation(description: "Calculate route called")
        calculateRouteCalled.assertForOverFulfill = false
        
        directions.onCalculateRoute = { [unowned directions] in
            XCTAssertTrue((directions.lastCalculateOptions as? RouteOptions)?.initialManeuverAvoidanceRadius == 500)

            calculateRouteCalled.fulfill()
        }

        let speedMultiplier: TimeInterval = 100
        locationManager.speedMultiplier = speedMultiplier
        locationManager.startUpdatingLocation()
        waitForExpectations(timeout: TimeInterval(replyLocations.count) / speedMultiplier + 1, handler: nil)
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
