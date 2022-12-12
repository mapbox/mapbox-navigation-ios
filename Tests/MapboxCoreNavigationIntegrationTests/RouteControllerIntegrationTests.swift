import XCTest
import Turf
import MapboxDirections
import CoreLocation
@testable import MapboxCoreNavigation
import TestHelper
import MapboxNavigationNative
@_implementationOnly import MapboxCommon_Private
@_implementationOnly import MapboxNavigationNative_Private

class RouteControllerIntegrationTests: TestCase {
    var replayManager: ReplayLocationManager?
    var routeResponse: RouteResponse!
    var routeController: RouteController!

    override func setUp() {
        super.setUp()

        routeResponse = makeRouteResponse()
    }

    override func tearDown() {
        replayManager?.stopUpdatingLocation()

        routeController = nil
        replayManager = nil
        MapboxRoutingProvider.__testRoutesStub = nil

        super.tearDown()
    }

    func testRouteSnappingOvershooting() {
        let options = NavigationMatchOptions(coordinates: [
            .init(latitude: 59.337928, longitude: 18.076841),
            .init(latitude: 59.33865, longitude: 18.074935),
        ])
        let routeResponse = IndexedRouteResponse(routeResponse: Fixture.routeResponseFromMatches(at: "sthlm-double-back", options: options), routeIndex: 0)
        let locations = Array<CLLocation>.locations(from: "sthlm-double-back-replay").shiftedToPresent()
        let locationManager = ReplayLocationManager(locations: locations)
        replayManager = locationManager
        routeController = RouteController(indexedRouteResponse: routeResponse,
                                          customRoutingProvider: MapboxRoutingProvider(.offline),
                                          dataSource: self)
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
        let routeResponse = IndexedRouteResponse(routeResponse: RouteResponse(httpResponse: nil,
                                                                              routes: [route],
                                                                              options: .route(.init(locations: replayLocations, profileIdentifier: nil)),
                                                                              credentials: .mocked),
                                                 routeIndex: 0)

        guard let lastReplayLocation = replayLocations.last else {
            XCTFail("First and last route locations should be valid.")
            return
        }

        routeController = RouteController(indexedRouteResponse: routeResponse,
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
                completionHandler(.success(routeResponse))

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
        let routeResponse = IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: "routeResponseWithAlternatives",
                                                                                      options: routeOptions),
                                                 routeIndex: 0)

        let alternativesExpectation = XCTestExpectation(description: "Alternative route should be reported")
        alternativesExpectation.assertForOverFulfill = true

        let routerDelegateSpy = RouterDelegateSpy()

        routerDelegateSpy.onDidUpdateAlternativeRoutes = { newAlternatives, removedAlternatives in
            XCTAssertTrue(removedAlternatives.isEmpty)
            if newAlternatives.count == 1 {
                alternativesExpectation.fulfill()
            }
        }

        routeController = RouteController(indexedRouteResponse: routeResponse,
                                          customRoutingProvider: MapboxRoutingProvider(.offline),
                                          dataSource: self)

        routeController.delegate = routerDelegateSpy

        wait(for: [alternativesExpectation], timeout: 2)
    }

    func testAlternativeRoutesNotReported() {
        let settingsValues = NavigationSettings.Values(directions: .mocked,
                                                       tileStoreConfiguration: .default,
                                                       routingProviderSource: .hybrid,
                                                       alternativeRouteDetectionStrategy: nil)
        NavigationSettings.shared.initialize(with: settingsValues)

        let routeOptions = RouteOptions(coordinates: [.init(latitude: 37.33243586131637,
                                                            longitude: -122.03140541047281),
                                                      .init(latitude: 37.33318065375225,
                                                            longitude: -122.03148874952787)],
                                        profileIdentifier: .automobileAvoidingTraffic)
        routeOptions.shapeFormat = .geoJSON
        let routeResponse = IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: "routeResponseWithAlternatives",
                                                                                      options: routeOptions),
                                                 routeIndex: 0)

        let alternativesExpectation = XCTestExpectation(description: "Alternative route should not be reported")
        alternativesExpectation.assertForOverFulfill = true
        alternativesExpectation.isInverted = true

        let routerDelegateSpy = RouterDelegateSpy()

        routerDelegateSpy.onDidUpdateAlternativeRoutes = { newAlternatives, removedAlternatives in
            alternativesExpectation.fulfill()
        }

        routeController = RouteController(indexedRouteResponse: routeResponse,
                                          customRoutingProvider: MapboxRoutingProvider(.offline),
                                          dataSource: self)

        routeController.delegate = routerDelegateSpy

        wait(for: [alternativesExpectation], timeout: 2)
    }

    func testCustomRoutingProvider() {
        let routingProviderStub = CustomRoutingProviderStub()
        let routeExpectation = XCTestExpectation(description: "Route calculation should be called")

        routingProviderStub.indexedRouteStub = { _ in
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

        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse,
                                                        routeIndex: 0)
        routeController = RouteController(indexedRouteResponse: indexedRouteResponse,
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

        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse,
                                                        routeIndex: 0)
        routeController = RouteController(indexedRouteResponse: indexedRouteResponse,
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

    func testSwitchToOnlineRoute() {
        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse,
                                                        routeIndex: 0,
                                                        responseOrigin: .onboard)
        routeController = RouteController(indexedRouteResponse: indexedRouteResponse,
                                          customRoutingProvider: MapboxRoutingProvider(.offline),
                                          dataSource: self)
        let routerDelegateSpy = RouterDelegateSpy()
        routeController.delegate = routerDelegateSpy

        expectation(forNotification: .routeControllerDidSwitchToCoincidentOnlineRoute, object: routeController)

        let routeOptions = indexedRouteResponse.validatedRouteOptions
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        guard let routeData = try? encoder.encode(indexedRouteResponse.routeResponse),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
                  XCTFail()
                  return
        }
        let routeRequest = Directions(credentials: indexedRouteResponse.routeResponse.credentials)
                                .url(forCalculating: routeOptions).absoluteString
        let parsedRoutes = RouteParser.parseDirectionsResponse(forResponse: routeJSONString,
                                                               request: routeRequest,
                                                               routeOrigin: indexedRouteResponse.responseOrigin)
        let userInfo: [MapboxCoreNavigation.Navigator.NotificationUserInfoKey: Any] = [
            .coincideOnlineRouteKey: (parsedRoutes.value as! [RouteInterface]).first!
        ]
        NotificationCenter.default.post(name: .navigatorWantsSwitchToCoincideOnlineRoute, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: 2)
    }

    func testProactiveRerouting() {
        let defaultInterval = RouteControllerProactiveReroutingInterval
        RouteControllerProactiveReroutingInterval = 1

        let coordinates = [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ]

        let options = NavigationRouteOptions(coordinates: coordinates)
        let route = Fixture.route(from: "DCA-Arboretum", options: options)
        let replayLocations = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
        let routeResponse = RouteResponse(httpResponse: nil,
                                          routes: [route],
                                          options: .route(.init(locations: replayLocations,
                                                                profileIdentifier: nil)),
                                          credentials: .mocked)

        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse,
                                                        routeIndex: 0)

        let routingProviderStub = CustomRoutingProviderStub()

        routingProviderStub.indexedRouteStub = { completion in
            let route = Fixture.route(from: "DCA-Arboretum-duration-edited", options: options)
            let replayLocations = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
            let routeResponse = RouteResponse(httpResponse: nil,
                                              routes: [route],
                                              options: .route(.init(locations: replayLocations,
                                                                    profileIdentifier: nil)),
                                              credentials: .mocked)

            completion(.success(IndexedRouteResponse(routeResponse: routeResponse,
                                                     routeIndex: 0)))
        }

        routeController = RouteController(indexedRouteResponse: indexedRouteResponse,
                                          customRoutingProvider: routingProviderStub,
                                          dataSource: self)
        let routerDelegateSpy = RouterDelegateSpy()
        let routeExpectation = XCTestExpectation(description: "Proactive ReRoute should be called")

        routerDelegateSpy.onShouldProactivelyRerouteFrom = { _, _ in
            routeExpectation.fulfill()
            return true
        }

        routeController.delegate = routerDelegateSpy

        let locationManager = ReplayLocationManager(locations: [CLLocation(coordinate: coordinates[0])].shiftedToPresent())
        locationManager.startDate = Date()
        locationManager.delegate = routeController

        locationManager.speedMultiplier = 1
        locationManager.startUpdatingLocation()
        wait(for: [routeExpectation], timeout: 15)

        RouteControllerProactiveReroutingInterval = defaultInterval
    }
}

extension RouteControllerIntegrationTests: RouterDataSource {
    var location: CLLocation? {
        return replayManager?.location
    }

    var locationManagerType: NavigationLocationManager.Type {
        return NavigationLocationManager.self
    }
}

class CustomRoutingProviderStub: RoutingProvider {
    var routeStub: (() -> Void)?
    var indexedRouteStub: ((IndexedRouteResponseCompletionHandler) -> Void)?
    var matchStub: (() -> Void)?
    var refreshStub: (() -> Void)?
    var refreshByIndexStub: (() -> Void)?

    func calculateRoutes(options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        routeStub?()
        return nil
    }

    func calculateRoutes(options: RouteOptions, completionHandler: @escaping IndexedRouteResponseCompletionHandler) -> NavigationProviderRequest? {
        indexedRouteStub?(completionHandler)
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

    func refreshRoute(indexedRouteResponse: IndexedRouteResponse, fromLegAtIndex: UInt32, currentRouteShapeIndex: Int, currentLegShapeIndex: Int, completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        refreshByIndexStub?()
        return nil
    }
}
