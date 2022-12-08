import XCTest
import MapboxDirections
import Turf
import CoreLocation
@testable import TestHelper
@testable import MapboxCoreNavigation

class NavigationServiceTests: TestCase {
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

    let expectationsTimeout = 1.0

    let indexedRouteResponse = IndexedRouteResponse.init(routeResponse: Fixture.routeResponse(from: jsonFileName, options: routeOptions), routeIndex: 0)
    var location: CLLocation!
    var lastLocation: CLLocation!

    var delegate: NavigationServiceDelegateSpy!
    var locationManager: NavigationLocationManagerSpy!
    var customRoutingProvider: RoutingProviderSpy!
    var poorGPSTimer: DispatchTimerSpy!

    var service: MapboxNavigationService!

    var route: Route {
        return indexedRouteResponse.currentRoute!
    }

    var routeProgress: RouteProgress {
        return service.router.routeProgress
    }

    var routerSpy: RouterSpy {
        return service.router as! RouterSpy
    }

    var eventsManager: NavigationEventsManagerSpy {
        return service.eventsManager as! NavigationEventsManagerSpy
    }

    var waypoint: Waypoint {
        return route.legs.last!.destination!
    }

    override func setUp() {
        super.setUp()

        delegate = NavigationServiceDelegateSpy()
        locationManager = NavigationLocationManagerSpy()
        customRoutingProvider = RoutingProviderSpy()
        poorGPSTimer = DispatchTimerSpy(countdown: .microseconds(2500), payload: {})

        service = makeService()

        let coordinate = routeProgress.nearbyShape.coordinates.first!
        location = CLLocation(coordinate: coordinate, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

        let lastCoordinate = routeProgress.remainingSteps.last!.shape!.coordinates.first!
        lastLocation = CLLocation(coordinate: lastCoordinate, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())
    }
    
    override func tearDown() {
        super.tearDown()

        MapboxRoutingProvider.__testRoutesStub = nil
    }

    private func makeService(customRoutingProvider: RoutingProvider? = nil,
                             simulating: SimulationMode = .never) -> MapboxNavigationService {
        let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                        customRoutingProvider: customRoutingProvider,
                                                        credentials: Fixture.credentials,
                                                        locationSource: locationManager,
                                                        eventsManagerType: NavigationEventsManagerSpy.self,
                                                        simulating: simulating,
                                                        routerType: RouterSpy.self,
                                                        customActivityType: .automotiveNavigation,
                                                        simulatedLocationSourceType: SimulatedLocationManagerSpy.self,
                                                        poorGPSTimer: poorGPSTimer)
        navigationService.delegate = delegate
        return navigationService
    }

    func testDefaultUserInterfaceUsage() {
        let usesDefaultUserInterface = Bundle.usesDefaultUserInterface
        
        // When building via Xcode when using SPM `MapboxNavigation` bundle will be present.
        if let _ = Bundle.mapboxNavigationIfInstalled {
            // Even though `MapboxCoreNavigationTests` does not directly link `MapboxNavigation`, it uses
            // `TestHelper`, which in turn uses `MapboxNavigation`. This means that its bundle will be present
            // in `MapboxCoreNavigationTests.xctest`.
            XCTAssertTrue(usesDefaultUserInterface, "Due to indirect linkage, `MapboxNavigation` will be linked to `MapboxCoreNavigationTests`.")
        } else {
            XCTAssertFalse(usesDefaultUserInterface, "MapboxCoreNavigationTests shouldn't have an implicit dependency on MapboxNavigation due to removing the Example application target as the test host.")
        }
    }

    func testStartIfNeverSimulation() {
        let notificationExpectation = expectation(forNotification: .navigationServiceSimulationDidChange, object: service)
        notificationExpectation.isInverted = true
        service.start()

        XCTAssertTrue(locationManager.startUpdatingHeadingCalled)
        XCTAssertTrue(locationManager.startUpdatingLocationCalled)
        XCTAssertTrue(eventsManager.hasImmediateEvent(with: EventType.routeRetrieval.rawValue))

        XCTAssertTrue(routerSpy.delegate === service)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testStartIfAlwaysSimulation() {
        service = makeService(simulating: .always)
        let notificationExpectation = expectation(forNotification: .navigationServiceSimulationDidChange, object: service)
        notificationExpectation.expectedFulfillmentCount = 2

        service.start()

        XCTAssertTrue(locationManager.startUpdatingHeadingCalled)
        XCTAssertTrue(locationManager.startUpdatingLocationCalled)
        XCTAssertTrue(eventsManager.hasImmediateEvent(with: EventType.routeRetrieval.rawValue))

        XCTAssertTrue(routerSpy.delegate === service)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testStartIfNonNilRouterLocation() {
        routerSpy.location = location
        service.start()

        XCTAssertFalse(routerSpy.didUpdateLocationsCalled)
    }

    func testStartIfNilRouterLocationAndNonNilManagerLocation() {
        locationManager.returnedLocation = location
        service.start()

        XCTAssertTrue(routerSpy.didUpdateLocationsCalled)
        XCTAssertEqual(routerSpy.passedLocations, [location])
    }

    func testStartIfNilRouterLocationAndSimulatedLocation() {
        let coordinate = route.shape!.coordinates.first!
        service.start()

        XCTAssertTrue(routerSpy.didUpdateLocationsCalled)
        XCTAssertEqual(routerSpy.passedLocations?.first?.coordinate, coordinate)
    }

    func testDidChangeAuthorization() {
        guard #available(iOS 14.0, *) else { return }
        expectation(forNotification: .locationAuthorizationDidChange, object: locationManager)
        service.locationManagerDidChangeAuthorization(locationManager)

        let expectedCalls = ["navigationServiceDidChangeAuthorization(_:didChangeAuthorizationFor:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateRoute() {
        let callbackExpectation = expectation(description: "Completion called")
        service.updateRoute(with: indexedRouteResponse,
                            routeOptions: indexedRouteResponse.validatedRouteOptions) { result in
            XCTAssertTrue(result)
            callbackExpectation.fulfill()
        }
        XCTAssertTrue(routerSpy.updateRouteCalled)
        XCTAssertEqual(routerSpy.passedRouteOptions, indexedRouteResponse.validatedRouteOptions)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testReturnCustomRoutingProvider() {
        let serviceWithoutCustomProvider = makeService(customRoutingProvider: nil)
        XCTAssertNil(serviceWithoutCustomProvider.customRoutingProvider)

        let serviceWithCustomProvider = makeService(customRoutingProvider: customRoutingProvider)
        XCTAssertTrue(serviceWithCustomProvider.customRoutingProvider as? RoutingProviderSpy === customRoutingProvider)
    }

    @available(*, deprecated)
    func testReturnRoutingProvider() {
        XCTAssertTrue(service.routingProvider as? RoutingProviderSpy === routerSpy.routingProviderSpy)
    }

    func testDidUpdateHeading() {
        let heading = CLHeading(heading: 5.0, accuracy: 1.0)!
        service.locationManager(locationManager, didUpdateHeading: heading)

        XCTAssertTrue(routerSpy.didUpdateHeadingCalled)
        XCTAssertEqual(routerSpy.passedHeading, heading)
    }

    func testDidUpdateLocationsIfAlwaysSimulation() {
        service.simulationMode = .always
        service.locationManager(locationManager, didUpdateLocations: [location])
        XCTAssertFalse(routerSpy.didUpdateLocationsCalled)
        XCTAssertEqual(eventsManager.locations, [])
        XCTAssertFalse(poorGPSTimer.resetCalled)
    }
    
    func testDidUpdateLocationsIfNoSimulation() {
        service.locationManager(locationManager, didUpdateLocations: [location])
        XCTAssertTrue(routerSpy.didUpdateLocationsCalled)
        XCTAssertEqual(routerSpy.passedLocationManager, locationManager)
        XCTAssertEqual(routerSpy.passedLocations, [location])
        XCTAssertEqual(eventsManager.locations, [location])
    }

    func testDidUpdateLocationsIfSimulationOnPoorGPS() {
        service.simulationMode = .onPoorGPS
        service.locationManager(locationManager, didUpdateLocations: [location])
        XCTAssertTrue(routerSpy.didUpdateLocationsCalled)
        XCTAssertEqual(routerSpy.passedLocationManager, locationManager)
        XCTAssertEqual(routerSpy.passedLocations, [location])
        XCTAssertTrue(poorGPSTimer.resetCalled)
    }

    func testDoNotUpdateLocationsWithEmptyLocations() {
        service.locationManager(locationManager, didUpdateLocations: [])
        XCTAssertFalse(routerSpy.didUpdateLocationsCalled)
    }

    func testStopIfNoSimulation() {
        let notificationExpectation = expectation(forNotification: .navigationServiceSimulationDidChange, object: service)
        notificationExpectation.isInverted = true

        service.stop()

        XCTAssertTrue(locationManager.stopUpdatingHeadingCalled)
        XCTAssertTrue(locationManager.stopUpdatingLocationCalled)
        XCTAssertFalse(eventsManager.hasImmediateEvent(with: EventType.cancel.rawValue))

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSetOnPoorGPSSimulationMode() {
        service.simulationMode = .onPoorGPS
        XCTAssertTrue(poorGPSTimer.armCalled)
        XCTAssertFalse(poorGPSTimer.disarmCalled)
        XCTAssertFalse( service.locationManager is SimulatedLocationManager)
    }

    func testSetInTunnelsSimulationMode() {
        service.simulationMode = .inTunnels
        XCTAssertTrue(poorGPSTimer.armCalled)
        XCTAssertFalse(poorGPSTimer.disarmCalled)
        XCTAssertFalse( service.locationManager is SimulatedLocationManager)
    }

    func testSetAlwaysSimulationMode() {
        var callbackCalls = 0
        let notificationExpectation = expectation(forNotification: .navigationServiceSimulationDidChange, object: service) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let simulationState = userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulationStateKey] as? SimulationState

            XCTAssertEqual(simulationState, callbackCalls == 0 ? .willBeginSimulation : .didBeginSimulation)
            callbackCalls += 1

            return true
        }
        notificationExpectation.expectedFulfillmentCount = 2
        routerSpy.routeProgress.currentLegProgress.stepIndex = 1
        let distanceTraveled = route.legs[0].steps[0].distance

        service.simulationMode = .always
        let simulatedLocationManager = service.locationManager as! SimulatedLocationManagerSpy
        XCTAssertEqual(simulatedLocationManager.currentDistance, distanceTraveled)
        XCTAssertTrue(simulatedLocationManager.route === route)
        XCTAssertTrue(simulatedLocationManager.startUpdatingLocationCalled)
        XCTAssertTrue(simulatedLocationManager.startUpdatingHeadingCalled)
        XCTAssertFalse(simulatedLocationManager.stopUpdatingLocationCalled)
        XCTAssertFalse(simulatedLocationManager.stopUpdatingHeadingCalled)
        XCTAssertTrue(simulatedLocationManager.delegate === service)
        XCTAssertEqual(simulatedLocationManager.speedMultiplier, 1.0)
        let expectedCalls = [
            "navigationService(_:willBeginSimulating:becauseOf:)",
            "navigationService(_:didBeginSimulating:becauseOf:)"
        ]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
        XCTAssertFalse(poorGPSTimer.armCalled)
        XCTAssertFalse(poorGPSTimer.disarmCalled)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSetNeverSimulationMode() {
        service.simulationMode = .always
        poorGPSTimer.resetTestValues()
        delegate.reset()
        let simulatedLocationManager = service.locationManager as! SimulatedLocationManagerSpy
        simulatedLocationManager.reset()

        var callbackCalls = 0
        let notificationExpectation = expectation(forNotification: .navigationServiceSimulationDidChange, object: service) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let simulationState = userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulationStateKey] as? SimulationState

            XCTAssertEqual(simulationState, callbackCalls == 0 ? .willEndSimulation : .didEndSimulation)
            callbackCalls += 1

            return true
        }
        notificationExpectation.expectedFulfillmentCount = 2

        service.simulationMode = .never
        XCTAssertTrue(poorGPSTimer.disarmCalled)
        XCTAssertFalse(simulatedLocationManager.startUpdatingLocationCalled)
        XCTAssertFalse(simulatedLocationManager.startUpdatingHeadingCalled)
        XCTAssertTrue(simulatedLocationManager.stopUpdatingLocationCalled)
        XCTAssertTrue(simulatedLocationManager.stopUpdatingHeadingCalled)
        XCTAssertNil(simulatedLocationManager.delegate)
        let expectedCalls = [
            "navigationService(_:willEndSimulating:becauseOf:)",
            "navigationService(_:didEndSimulating:becauseOf:)"
        ]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSimulationSpeedMultiplier() {
        let expectedSimulationSpeedMultiplier = 2.0

        service.simulationMode = .never
        service.simulationSpeedMultiplier = expectedSimulationSpeedMultiplier
        XCTAssertEqual(service.simulationSpeedMultiplier, 1.0, "Should not update simulationSpeedMultiplier if in .never simulation mode")

        service.simulationMode = .onPoorGPS
        service.simulationSpeedMultiplier = expectedSimulationSpeedMultiplier
        XCTAssertEqual(service.simulationSpeedMultiplier, 1.0, "Should not update simulationSpeedMultiplier if in .onPoorGPS simulation mode")

        service.simulationMode = .inTunnels
        service.simulationSpeedMultiplier = expectedSimulationSpeedMultiplier
        XCTAssertEqual(service.simulationSpeedMultiplier, 1.0, "Should not update simulationSpeedMultiplier if in .inTunnels simulation mode")

        service.simulationMode = .always
        service.simulationSpeedMultiplier = expectedSimulationSpeedMultiplier
        XCTAssertEqual(service.simulationSpeedMultiplier, expectedSimulationSpeedMultiplier, "Should update simulationSpeedMultiplier if in .always simulation mode")

        service.simulationMode = .onPoorGPS
        XCTAssertEqual(service.simulationSpeedMultiplier, 1.0, "Should use default simulationSpeedMultiplier if not in .always simulation mode")

        service.simulationMode = .always
        XCTAssertEqual(service.simulationSpeedMultiplier, expectedSimulationSpeedMultiplier, "Should use updated value if in .always simulation mode")
    }

    func testStopIfAlwaysSimulationMode() {
        let expectedSimulationSpeedMultiplier = 2.0
        service.simulationMode = .always
        service.simulationSpeedMultiplier = expectedSimulationSpeedMultiplier
        delegate.reset()

        var callbackCalls = 0
        let notificationExpectation = expectation(forNotification: .navigationServiceSimulationDidChange, object: service) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let simulationState = userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulationStateKey] as? SimulationState
            let simulationSpeedMultiplier = userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulatedSpeedMultiplierKey] as? Double

            XCTAssertEqual(simulationState, callbackCalls == 0 ? .willEndSimulation : .didEndSimulation)
            XCTAssertEqual(simulationSpeedMultiplier, expectedSimulationSpeedMultiplier)
            callbackCalls += 1

            return true
        }
        notificationExpectation.expectedFulfillmentCount = 2

        service.stop()

        XCTAssertTrue(locationManager.stopUpdatingHeadingCalled)
        XCTAssertTrue(locationManager.stopUpdatingLocationCalled)
        let expectedCalls = [
            "navigationService(_:willEndSimulating:becauseOf:)",
            "navigationService(_:didEndSimulating:becauseOf:)"
        ]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testEndNavigationIfSimulation() {
        let expectedSimulationSpeedMultiplier = 2.0
        service.simulationMode = .always
        service.simulationSpeedMultiplier = expectedSimulationSpeedMultiplier
        delegate.reset()
        var callbackCalls = 0
        let notificationExpectation = expectation(forNotification: .navigationServiceSimulationDidChange, object: service) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let simulationState = userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulationStateKey] as? SimulationState
            let simulationSpeedMultiplier = userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulatedSpeedMultiplierKey] as? Double

            XCTAssertEqual(simulationState, callbackCalls == 0 ? .willEndSimulation : .didEndSimulation)
            XCTAssertEqual(simulationSpeedMultiplier, expectedSimulationSpeedMultiplier)
            callbackCalls += 1

            return true
        }
        notificationExpectation.expectedFulfillmentCount = 2

        let feedback = EndOfRouteFeedback(rating: 5, comment: "comment")
        service.endNavigation(feedback: feedback)

        XCTAssertTrue(eventsManager.hasImmediateEvent(with: EventType.cancel.rawValue))
        XCTAssertTrue(locationManager.stopUpdatingHeadingCalled)
        XCTAssertTrue(locationManager.stopUpdatingLocationCalled)

        let expectedCalls = [
            "navigationService(_:willEndSimulating:becauseOf:)",
            "navigationService(_:didEndSimulating:becauseOf:)"
        ]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
        XCTAssertNil(routerSpy.delegate)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testEndNavigationIfSimulationInTunnel() {
        service.simulationMode = .inTunnels
        delegate.reset()

        expectation(forNotification: .navigationServiceSimulationDidChange, object: service) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let simulationState = userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulationStateKey] as? SimulationState
            let simulationSpeedMultiplier = userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulatedSpeedMultiplierKey] as? Double

            XCTAssertEqual(simulationState, .notInSimulation)
            XCTAssertEqual(simulationSpeedMultiplier, 1.0)

            return true
        }

        let feedback = EndOfRouteFeedback(rating: 5, comment: "comment")
        service.endNavigation(feedback: feedback)

        XCTAssertTrue(eventsManager.hasImmediateEvent(with: EventType.cancel.rawValue))
        XCTAssertTrue(locationManager.stopUpdatingHeadingCalled)
        XCTAssertTrue(locationManager.stopUpdatingLocationCalled)

        XCTAssertEqual(delegate.recentMessages, [])
        XCTAssertNil(routerSpy.delegate)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testEndNavigationIfNoSimulation() {
        service.simulationMode = .never
        delegate.reset()

        let notificationExpectation = expectation(forNotification: .navigationServiceSimulationDidChange, object: service)
        notificationExpectation.isInverted = true

        let feedback = EndOfRouteFeedback(rating: 5, comment: "comment")
        service.endNavigation(feedback: feedback)

        XCTAssertTrue(eventsManager.hasImmediateEvent(with: EventType.cancel.rawValue))
        XCTAssertTrue(locationManager.stopUpdatingHeadingCalled)
        XCTAssertTrue(locationManager.stopUpdatingLocationCalled)
        XCTAssertEqual(delegate.recentMessages, [])
        XCTAssertNil(routerSpy.delegate)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testWillRerouteFrom() {
        routeProgress.currentLegProgress.currentStepProgress.distanceTraveled = 10
        service.router(routerSpy, willRerouteFrom: location)
        XCTAssertTrue(eventsManager.enqueueRerouteEventCalled)
        XCTAssertEqual(eventsManager.totalDistanceCompleted, routeProgress.distanceTraveled)
        let expectedCalls = ["navigationService(_:willRerouteFrom:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testModifyOptionsForReroute() {
        let expectedRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268)
        ])
        let routeOptions = service.router(routerSpy, modifiedOptionsForReroute: expectedRouteOptions)
        XCTAssertEqual(routeOptions, expectedRouteOptions)
        let expectedCalls = ["navigationService(_:modifiedOptionsForReroute:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidRerouteAlong() {
        service.router(routerSpy, didRerouteAlong: route, at: location, proactive: true)
        let expectedCalls = ["navigationService(_:didRerouteAlong:at:proactive:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidFailToReroute() {
        let error = DirectionsError.noData
        service.router(routerSpy, didFailToRerouteWith: error)
        let expectedCalls = ["navigationService(_:didFailToRerouteWith:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidRefresh() {
        service.router(routerSpy, didRefresh: routeProgress)
        let expectedCalls = ["navigationService(_:didRefresh:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidUpdate() {
        service.router(routerSpy, didUpdate: routeProgress, with: location, rawLocation: lastLocation)
        XCTAssertTrue(eventsManager.hasImmediateEvent(with: EventType.depart.rawValue))
        let expectedCalls = ["navigationService(_:didUpdate:with:rawLocation:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidPassVisualInstructionPoint() {
        let visualInstruction = Fixture.makeVisualInstruction()
        service.router(routerSpy, didPassVisualInstructionPoint: visualInstruction, routeProgress: routeProgress)
        let expectedCalls = ["navigationService(_:didPassVisualInstructionPoint:routeProgress:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidPassSpokenInstructionPoint() {
        let spokenInstruction = Fixture.makeSpokenInstruction()
        service.router(routerSpy, didPassSpokenInstructionPoint: spokenInstruction, routeProgress: routeProgress)
        let expectedCalls = ["navigationService(_:didPassSpokenInstructionPoint:routeProgress:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testReturnShouldRerouteFromIfDefault() {
        service.delegate = nil
        XCTAssertTrue(service.router(routerSpy, shouldRerouteFrom: location))
    }

    func testReturnShouldRerouteFrom() {
        delegate.returnedShouldReroute = false
        XCTAssertFalse(service.router(routerSpy, shouldRerouteFrom: location))
        XCTAssertEqual(delegate.passedLocation, location)

        delegate.returnedShouldReroute = true
        XCTAssertTrue(service.router(routerSpy, shouldRerouteFrom: location))
    }

    func testReturnShouldDiscardIfDefault() {
        service.delegate = nil
        XCTAssertFalse(service.router(routerSpy, shouldDiscard: location))
    }

    func testReturnShouldDiscard() {
        delegate.returnedShouldDiscard = false
        XCTAssertFalse(service.router(routerSpy, shouldDiscard: location))
        XCTAssertEqual(delegate.passedLocation, location)

        delegate.returnedShouldDiscard = true
        XCTAssertTrue(service.router(routerSpy, shouldDiscard: location))
    }

    func testReturnShouldPreventReroutesIfDefault() {
        service.delegate = nil
        XCTAssertTrue(service.router(routerSpy, shouldPreventReroutesWhenArrivingAt: waypoint))
    }

    func testReturnShouldPreventReroutes() {
        delegate.returnedShouldPreventReroutesWhenArrivingAt = false
        XCTAssertFalse(service.router(routerSpy, shouldPreventReroutesWhenArrivingAt: waypoint))
        XCTAssertEqual(delegate.passedWaypoint, waypoint)

        delegate.returnedShouldPreventReroutesWhenArrivingAt = true
        XCTAssertTrue(service.router(routerSpy, shouldPreventReroutesWhenArrivingAt: waypoint))
    }

    func testReturnShouldDisableBatteryMonitoringIfDefault() {
        service.delegate = nil
        XCTAssertTrue(service.routerShouldDisableBatteryMonitoring(routerSpy))
    }

    func testReturnShouldDisableBatteryMonitoring() {
        delegate.returnedShouldDisableBatteryMonitoring = false
        XCTAssertFalse(service.routerShouldDisableBatteryMonitoring(routerSpy))

        delegate.returnedShouldDisableBatteryMonitoring = true
        XCTAssertTrue(service.routerShouldDisableBatteryMonitoring(routerSpy))
    }

    func testWillArriveAt() {
        service.router(routerSpy, willArriveAt: waypoint, after: 100, distance: 1000)
        let expectedCalls = ["navigationService(_:willArriveAt:after:distance:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
        XCTAssertEqual(delegate.passedWaypoint, waypoint)
    }

    func testDidArriveAtIfDefault() {
        service.delegate = nil
        XCTAssertTrue(service.router(routerSpy, didArriveAt: waypoint))

        XCTAssertFalse(poorGPSTimer.disarmCalled)
        XCTAssertFalse(locationManager.stopUpdatingHeadingCalled)
        XCTAssertFalse(locationManager.stopUpdatingLocationCalled)
    }

    func testDidArriveAtIfLastWaypoint() {
        XCTAssertTrue(service.router(routerSpy, didArriveAt: waypoint))
        XCTAssertTrue(eventsManager.arriveAtDestinationCalled)
        XCTAssertFalse(eventsManager.arriveAtWaypointCalled)
    }

    func testDidArriveAtIfNotLastWaypoint() {
        let response = makeMultilegRouteResponse()
        routerSpy.routeProgress = RouteProgress(route: response.routes![0],
                                                options: indexedRouteResponse.validatedRouteOptions)
        XCTAssertTrue(service.router(routerSpy, didArriveAt: waypoint))
        XCTAssertFalse(eventsManager.arriveAtDestinationCalled)
        XCTAssertTrue(eventsManager.arriveAtWaypointCalled)
    }

    func testDidArriveAtIfDelegateReturnedTrue() {
        delegate.returnedDidArrive = true
        XCTAssertTrue(service.router(routerSpy, didArriveAt: waypoint))
        let expectedCalls = ["navigationService(_:didArriveAt:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
        XCTAssertEqual(delegate.passedWaypoint, waypoint)

        XCTAssertFalse(poorGPSTimer.disarmCalled)
        XCTAssertFalse(locationManager.stopUpdatingHeadingCalled)
        XCTAssertFalse(locationManager.stopUpdatingLocationCalled)
    }

    func testDidArriveAtIfDelegateReturnedFalse() {
        delegate.returnedDidArrive = false
        XCTAssertFalse(service.router(routerSpy, didArriveAt: waypoint))
        let expectedCalls = ["navigationService(_:didArriveAt:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
        XCTAssertEqual(delegate.passedWaypoint, waypoint)

        XCTAssertTrue(poorGPSTimer.disarmCalled)
        XCTAssertTrue(locationManager.stopUpdatingHeadingCalled)
        XCTAssertTrue(locationManager.stopUpdatingLocationCalled)
    }

    func testDidFailToUpdateAlternatives() {
        let error = AlternativeRouteError.failedToUpdateAlternativeRoutes(reason: "reason")
        service.router(routerSpy, didFailToUpdateAlternatives: error)
        let expectedCalls = ["navigationService(_:didFailToUpdateAlternatives:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidFailToTakeAlternativeRoad() {
        service.router(routerSpy, didFailToTakeAlternativeRouteAt: location)
        let expectedCalls = ["navigationService(_:didFailToTakeAlternativeRouteAt:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testWillTakeAlternativeRoad() {
        service.router(routerSpy, willTakeAlternativeRoute: route, at: location)
        let expectedCalls = ["navigationService(_:willTakeAlternativeRoute:at:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidTakeAlternativeRoad() {
        service.router(routerSpy, didTakeAlternativeRouteAt: location)
        let expectedCalls = ["navigationService(_:didTakeAlternativeRouteAt:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidSwitchToCoincidentOnlineRoute() {
        service.router(routerSpy, didSwitchToCoincidentOnlineRoute: route)
        let expectedCalls = ["navigationService(_:didSwitchToCoincidentOnlineRoute:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    func testDidUpdateAlternatives() {
        service.router(routerSpy, didUpdateAlternatives: [], removedAlternatives: [])
        let expectedCalls = ["navigationService(_:didUpdateAlternatives:removedAlternatives:)"]
        XCTAssertEqual(delegate.recentMessages, expectedCalls)
    }

    private func makeMultilegRouteResponse() -> RouteResponse {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268),
            CLLocationCoordinate2D(latitude: 47.212326, longitude: 9.512569),
        ])
        return Fixture.routeResponse(from: "multileg-route", options: routeOptions)
    }
}
