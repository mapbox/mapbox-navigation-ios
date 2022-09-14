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
        let routeController = RouteController(alongRouteAtIndex: 0, in: routeResponse, options: equivalentRouteOptions, customRoutingProvider: MapboxRoutingProvider(.offline), dataSource: self)
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
                                              customRoutingProvider: MapboxRoutingProvider(.offline),
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
                
                calculateRouteCalled.fulfill()
            }
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
    
    func testAlternativeRoutesReported() {
        let routeOptions = RouteOptions(coordinates: [.init(latitude: 37.33243586131637,
                                                            longitude: -122.03140541047281),
                                                      .init(latitude: 37.33318065375225,
                                                            longitude: -122.03148874952787)],
                                        profileIdentifier: .automobileAvoidingTraffic)
        routeOptions.shapeFormat = .geoJSON
        let routeResponse = Fixture.routeResponse(from: "routeResponseWithAlternatives",
                                                  options: routeOptions)
        
        let alternativesExpectation = XCTestExpectation(description: "Alternative route should be reported")
        alternativesExpectation.assertForOverFulfill = true
        
        let routerDelegateSpy = RouterDelegateSpy()
        
        routerDelegateSpy.onDidUpdateAlternativeRoutes = { newAlternatives, removedAlternatives in
            XCTAssertTrue(removedAlternatives.isEmpty)
            if newAlternatives.count == 1 {
                alternativesExpectation.fulfill()
            }
        }
        
        let routeController = RouteController(alongRouteAtIndex: 0,
                                              in: routeResponse,
                                              options: routeOptions,
                                              customRoutingProvider: MapboxRoutingProvider(.offline),
                                              dataSource: self)
        
        routeController.delegate = routerDelegateSpy
        
        wait(for: [alternativesExpectation], timeout: 2)
    }
    
    func testAlternativeRoutesNotReported() {
        NavigationSettings.shared.initialize(directions: .mocked,
                                             tileStoreConfiguration: .default,
                                             routingProviderSource: .hybrid,
                                             alternativeRouteDetectionStrategy: nil)
        
        let routeOptions = RouteOptions(coordinates: [.init(latitude: 37.33243586131637,
                                                            longitude: -122.03140541047281),
                                                      .init(latitude: 37.33318065375225,
                                                            longitude: -122.03148874952787)],
                                        profileIdentifier: .automobileAvoidingTraffic)
        routeOptions.shapeFormat = .geoJSON
        let routeResponse = Fixture.routeResponse(from: "routeResponseWithAlternatives",
                                                  options: routeOptions)
        
        let alternativesExpectation = XCTestExpectation(description: "Alternative route should not be reported")
        alternativesExpectation.assertForOverFulfill = true
        alternativesExpectation.isInverted = true
        
        let routerDelegateSpy = RouterDelegateSpy()
        
        routerDelegateSpy.onDidUpdateAlternativeRoutes = { newAlternatives, removedAlternatives in
            alternativesExpectation.fulfill()
        }
        
        let routeController = RouteController(alongRouteAtIndex: 0,
                                              in: routeResponse,
                                              options: routeOptions,
                                              customRoutingProvider: MapboxRoutingProvider(.offline),
                                              dataSource: self)
        
        routeController.delegate = routerDelegateSpy
        
        wait(for: [alternativesExpectation], timeout: 2)
    }
    
    func testCustomRoutingProvider() {
        let routingProviderStub = CustomRoutingProviderStub()
        let routeExpectation = XCTestExpectation(description: "Route calculation should be called")
        
        routingProviderStub.routeStub = {
            routeExpectation.fulfill()
        }
        
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.750384, longitude: -122.387487),
            CLLocationCoordinate2D(latitude: 37.764343, longitude: -122.388664),
        ]
        
        let options = NavigationRouteOptions(coordinates: coordinates)
        let route = Fixture.route(from: "route-for-off-route", options: options)
        let replayLocations = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
        let routeResponse = RouteResponse(httpResponse: nil,
                                          routes: [route],
                                          options: .route(.init(locations: replayLocations, profileIdentifier: nil)),
                                          credentials: .mocked)
        
        let offRouteLocation = CLLocationCoordinate2D(latitude: coordinates[1].latitude,
                                                      longitude: -coordinates[1].longitude)
        let offRouteReplayLocation = Fixture.generateCoordinates(between: coordinates[0],
                                                                 and: offRouteLocation,
                                                                 count: 100).map {
            CLLocation(coordinate: $0)
        }.shiftedToPresent()
        
        let routeController = RouteController(alongRouteAtIndex: 0,
                                              in: routeResponse,
                                              options: options,
                                              customRoutingProvider: routingProviderStub,
                                              dataSource: self)
        
        let locationManager = ReplayLocationManager(locations: offRouteReplayLocation)
        locationManager.startDate = Date()
        locationManager.delegate = routeController
        
        locationManager.speedMultiplier = 50
        locationManager.startUpdatingLocation()
        wait(for: [routeExpectation], timeout: locationManager.expectedReplayTime)
    }
    
    func testReroutingUpdatesRouteOptions() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.750384, longitude: -122.387487),
            CLLocationCoordinate2D(latitude: 37.764343, longitude: -122.388664),
        ]
        
        let options = NavigationRouteOptions(coordinates: coordinates)
        let route = Fixture.route(from: "route-for-off-route", options: options)
        let replayLocations = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
        let routeResponse = RouteResponse(httpResponse: nil,
                                          routes: [route],
                                          options: .route(.init(locations: replayLocations, profileIdentifier: nil)),
                                          credentials: .mocked)
        
        let offRouteLocation = CLLocationCoordinate2D(latitude: coordinates[1].latitude,
                                                      longitude: -coordinates[1].longitude)
        let offRouteReplayLocation = Fixture.generateCoordinates(between: coordinates[0],
                                                                 and: offRouteLocation,
                                                                 count: 100).map {
            CLLocation(coordinate: $0)
        }.shiftedToPresent()
        
        let routeController = RouteController(alongRouteAtIndex: 0,
                                              in: routeResponse,
                                              options: options,
                                              customRoutingProvider: nil,
                                              dataSource: self)
        
        let routerDelegateSpy = RouterDelegateSpy()
        let modifyExpectation = expectation(description: "Reroute should request options editing.")
        modifyExpectation.assertForOverFulfill = false
        
        routerDelegateSpy.onModifiedOptionsForReroute = { options in
            modifyExpectation.fulfill()
            return options
        }
        routeController.delegate = routerDelegateSpy
        
        let locationManager = ReplayLocationManager(locations: offRouteReplayLocation)
        locationManager.startDate = Date()
        locationManager.delegate = routeController
        
        locationManager.speedMultiplier = 50
        locationManager.startUpdatingLocation()
        wait(for: [modifyExpectation], timeout: locationManager.expectedReplayTime)
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

class CustomRoutingProviderStub: RoutingProvider {
    var routeStub: (() -> Void)?
    var matchStub: (() -> Void)?
    var refreshStub: (() -> Void)?
    
    func calculateRoutes(options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        routeStub?()
        return nil
    }
    
    func calculateRoutes(options: MatchOptions, completionHandler: @escaping Directions.MatchCompletionHandler) -> NavigationProviderRequest? {
        matchStub?()
        return nil
    }
    
    func refreshRoute(indexedRouteResponse: IndexedRouteResponse, fromLegAtIndex: UInt32, completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        refreshStub?()
        return nil
    }
}
