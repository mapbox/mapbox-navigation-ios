import XCTest
import MapboxDirections
import Turf
import MapboxMobileEvents
import os.log
@testable import TestHelper
@testable import MapboxCoreNavigation

fileprivate let mbTestHeading: CLLocationDirection = 50

class NavigationServiceTests: XCTestCase {
    var eventsManagerSpy: NavigationEventsManagerSpy!
    let directionsClientSpy = DirectionsSpy()
    let delegate = NavigationServiceDelegateSpy()

    typealias RouteLocations = (firstLocation: CLLocation, penultimateLocation: CLLocation, lastLocation: CLLocation)

    lazy var dependencies: (navigationService: NavigationService, routeLocations: RouteLocations) = {
        let navigationService = MapboxNavigationService(route: initialRoute, routeOptions: routeOptions, directions: directionsClientSpy, eventsManagerType: NavigationEventsManagerSpy.self, simulating: .never)
        navigationService.delegate = delegate

        let legProgress: RouteLegProgress = navigationService.router.routeProgress.currentLegProgress

        let firstCoord = navigationService.router.routeProgress.nearbyShape.coordinates.first!
        let firstLocation = CLLocation(coordinate: firstCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

        let remainingSteps = legProgress.remainingSteps
        let penultimateCoord = legProgress.remainingSteps[4].shape!.coordinates.first!
        let penultimateLocation = CLLocation(coordinate: penultimateCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

        let lastCoord = legProgress.remainingSteps.last!.shape!.coordinates.first!
        let lastLocation = CLLocation(coordinate: lastCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

        let routeLocations = RouteLocations(firstLocation, penultimateLocation, lastLocation)

        return (navigationService: navigationService, routeLocations: routeLocations)
    }()

    let initialRoute = Fixture.route(from: jsonFileName, options: routeOptions)

    let alternateRoute = Fixture.route(from: jsonFileName, options: routeOptions)

    override func setUp() {
        super.setUp()

        directionsClientSpy.reset()
        delegate.reset()
    }

    func testDefaultUserInterfaceUsage() {
        XCTAssertTrue(dependencies.navigationService.eventsManager.usesDefaultUserInterface, "MapboxCoreNavigationTests should have an implicit dependency on MapboxNavigation due to running inside the Example application target.")
    }

    func testUserIsOnRoute() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertTrue(navigation.router.userIsOnRoute(firstLocation), "User should be on route")
    }

    func testUserIsOffRoute() {
        let navigation = dependencies.navigationService
        let route = navigation.route

        let coordinates = route.shape!.coordinates.prefix(3)
        let now = Date()
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: now + $0.offset) }

        locations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }

        XCTAssertTrue(navigation.router.userIsOnRoute(locations.last!), "User should be on route")

        let coordinatesOffRoute: [CLLocationCoordinate2D] = (0...3).map { _ in locations.first!.coordinate.coordinate(at: 100, facing: 90) }
        let locationsOffRoute = coordinatesOffRoute.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10,
                       verticalAccuracy: -1, course: -1, speed: 10,
                       timestamp: now + locations.count + $0.offset)
        }

        locationsOffRoute.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }

        XCTAssertFalse(navigation.router.userIsOnRoute(locationsOffRoute.last!), "User should be off route")
    }

    func testAdvancingToFutureStepAndNotRerouting() {
        let navigation = dependencies.navigationService
        let route = navigation.route

        let firstStepCoordinates = route.legs[0].steps[0].shape!.coordinates
        let now = Date()
        let firstStepLocations = firstStepCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: now + $0.offset)
        }

        firstStepLocations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        XCTAssertTrue(navigation.router.userIsOnRoute(firstStepLocations.last!), "User should be on route")
        XCTAssertEqual(navigation.router.routeProgress.currentLegProgress.stepIndex, 1, "User is on first step")

        let thirdStepCoordinates = route.legs[0].steps[2].shape!.coordinates
        let thirdStepLocations = thirdStepCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: now + firstStepCoordinates.count + $0.offset)
        }

        thirdStepLocations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }

        XCTAssertTrue(navigation.router.userIsOnRoute(thirdStepLocations.last!), "User should be on route")
        XCTAssertEqual(navigation.router.routeProgress.currentLegProgress.stepIndex, 3, "User should be on route and we should increment all the way to the 4th step")
    }

    func testSnappedLocation() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstLocation.coordinate.latitude, accuracy: 0.0005, "Check snapped location is working")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstLocation.coordinate.longitude, accuracy: 0.0005, "Check snapped location is working")
    }

    func testSnappedAtEndOfStepLocationWhenMovingSlowly() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        
        // Check snapped location is working
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstLocation.coordinate.latitude, accuracy: 0.005, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstLocation.coordinate.longitude, accuracy: 0.005, "Longitudes should be almost equal")

        let firstCoordinateOnUpcomingStep = navigation.router.routeProgress.currentLegProgress.upcomingStep!.shape!.coordinates.first!
        let firstLocationOnNextStepWithNoSpeed = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, course: 10, speed: 0, timestamp: Date())

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithNoSpeed])
        
        let lastCoordinate = navigation.router.routeProgress.currentLegProgress.currentStep.shape!.coordinates.last!
        
        // When user is not moving, snap to current leg only
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, lastCoordinate.latitude, accuracy: 0.005, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, lastCoordinate.longitude, accuracy: 0.005, "Longitudes should be almost equal")

        let firstLocationOnNextStepWithSpeed = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, course: 10, speed: 5, timestamp: Date())
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithSpeed])

        // User is snapped to upcoming step when moving
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstCoordinateOnUpcomingStep.latitude, accuracy: 0.005, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstCoordinateOnUpcomingStep.longitude, accuracy: 0.005, "Longitudes should be almost equal")
    }

    func testSnappedAtEndOfStepLocationWhenCourseIsSimilar() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.router.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")

        let firstCoordinateOnUpcomingStep = navigation.router.routeProgress.currentLegProgress.upcomingStep!.shape!.coordinates.first!

        let finalHeading = navigation.router.routeProgress.currentLegProgress.upcomingStep!.finalHeading!
        let firstLocationOnNextStepWithDifferentCourse = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 30, verticalAccuracy: 10, course: -finalHeading, speed: 5, timestamp: Date())

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithDifferentCourse])
        XCTAssertEqual(navigation.router.location!.coordinate, navigation.router.routeProgress.currentLegProgress.currentStep.shape!.coordinates.last!, "When user's course is dissimilar from the finalHeading, they should not snap to upcoming step")

        let firstLocationOnNextStepWithCorrectCourse = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 30, verticalAccuracy: 10, course: finalHeading, speed: 0, timestamp: Date())
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithCorrectCourse])
        XCTAssertEqual(navigation.router.location!.coordinate, firstCoordinateOnUpcomingStep, "User is snapped to upcoming step when their course is similar to the final heading")
    }

    func testSnappedLocationForUnqualifiedLocation() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])

        // Check snapped location is working
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstLocation.coordinate.latitude, accuracy: 0.005, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstLocation.coordinate.longitude, accuracy: 0.005, "Longitudes should be almost equal")

        let futureCoord = navigation.router.routeProgress.nearbyShape.coordinateFromStart(distance: 100)!
        let futureInaccurateLocation = CLLocation(coordinate: futureCoord, altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 200, course: 0, speed: 5, timestamp: Date())

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [futureInaccurateLocation])

        // Inaccurate location should still be snapped
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, futureInaccurateLocation.coordinate.latitude, accuracy: 0.005, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, futureInaccurateLocation.coordinate.longitude, accuracy: 0.005, "Longitudes should be almost equal")
    }

    func testUserPuckShouldFaceBackwards() {
        // This route is a simple straight line: http://geojson.io/#id=gist:anonymous/64cfb27881afba26e3969d06bacc707c&map=17/37.77717/-122.46484
        let directions = DirectionsSpy()
        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.77735, longitude: -122.461465),
            CLLocationCoordinate2D(latitude: 37.777016, longitude: -122.468832),
        ])
        let route = Fixture.route(from: "straight-line", options: options)

        let navigation = MapboxNavigationService(route: route, routeOptions: options, directions: directions)
        let router = navigation.router!
        let firstCoord = router.routeProgress.nearbyShape.coordinates.first!
        let firstLocation = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        let coordNearStart = router.routeProgress.nearbyShape.coordinateFromStart(distance: 10)!

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])

        // We're now 10 meters away from the last coord, looking at the start.
        // Basically, simulating moving backwards.
        let directionToStart = coordNearStart.direction(to: firstCoord)
        let facingTowardsStartLocation = CLLocation(coordinate: coordNearStart, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: directionToStart, speed: 0, timestamp: Date())

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [facingTowardsStartLocation])

        // The course should not be the interpolated course, rather the raw course.
        XCTAssertEqual(directionToStart, router.location!.course, "The course should be the raw course and not an interpolated course")
        XCTAssertFalse(facingTowardsStartLocation.shouldSnap(toRouteWith: facingTowardsStartLocation.interpolatedCourse(along: router.routeProgress.nearbyShape)!, distanceToFirstCoordinateOnLeg: facingTowardsStartLocation.distance(from: firstLocation)), "Should not snap")
    }

    //TODO: Broken by PortableRoutecontroller & MBNavigator -- needs team discussion.
    func x_testLocationShouldUseHeading() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])

        XCTAssertEqual(navigation.router.location!.course, firstLocation.course, "Course should be using course")

        let invalidCourseLocation = CLLocation(coordinate: firstLocation.coordinate, altitude: firstLocation.altitude, horizontalAccuracy: firstLocation.horizontalAccuracy, verticalAccuracy: firstLocation.verticalAccuracy, course: -1, speed: firstLocation.speed, timestamp: firstLocation.timestamp)

        let heading = CLHeading(heading: mbTestHeading, accuracy: 1)!

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [invalidCourseLocation])
        navigation.locationManager!(navigation.locationManager, didUpdateHeading: heading)

        XCTAssertEqual(navigation.router.location!.course, mbTestHeading, "Course should be using bearing")
    }

    // MARK: - Events & Delegation

    func testTurnstileEventSentUponInitialization() {
        // MARK: it sends a turnstile event upon initialization

        let service = MapboxNavigationService(route: initialRoute, routeOptions: routeOptions, directions: directionsClientSpy, locationSource: NavigationLocationManager(), eventsManagerType: NavigationEventsManagerSpy.self)
        let eventsManagerSpy = service.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEEventTypeAppUserTurnstile))
    }

    func testReroutingFromLocationUpdatesSimulatedLocationSource() {
        let navigationService = MapboxNavigationService(route: initialRoute, routeOptions: routeOptions,  directions: directionsClientSpy, eventsManagerType: NavigationEventsManagerSpy.self, simulating: .always)
        navigationService.delegate = delegate
        let router = navigationService.router!

        navigationService.eventsManager.delaysEventFlushing = false
        navigationService.start()

        let eventsManagerSpy = navigationService.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: NavigationEventTypeRouteRetrieval))

        router.route = alternateRoute

        let simulatedLocationManager = navigationService.locationManager as! SimulatedLocationManager

        XCTAssert(simulatedLocationManager.route == alternateRoute, "Simulated Location Manager should be updated with new route progress model")
    }

    func testReroutingFromALocationSendsEvents() {
        let navigationService = dependencies.navigationService
        let router = navigationService.router!
        let testLocation = dependencies.routeLocations.firstLocation

        navigationService.eventsManager.delaysEventFlushing = false

        let willRerouteNotificationExpectation = expectation(forNotification: .routeControllerWillReroute, object: router) { (notification) -> Bool in
            let fromLocation = notification.userInfo![RouteController.NotificationUserInfoKey.locationKey] as? CLLocation

            XCTAssertTrue(fromLocation == testLocation)

            return true
        }

        let didRerouteNotificationExpectation = expectation(forNotification: .routeControllerDidReroute, object: router, handler: nil)

        let routeProgressDidChangeNotificationExpectation = expectation(forNotification: .routeControllerProgressDidChange, object: router) { (notification) -> Bool in
            let location = notification.userInfo![RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            let rawLocation = notification.userInfo![RouteController.NotificationUserInfoKey.rawLocationKey] as? CLLocation
            let _ = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as! RouteProgress

            XCTAssertTrue(location!.distance(from: rawLocation!) <= 0.5)

            return true
        }

        // MARK: When told to re-route from location -- `reroute(from:)`
        router.reroute(from: testLocation, along: router.routeProgress)

        // MARK: it tells the delegate & posts a willReroute notification
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:willRerouteFrom:)"))
        wait(for: [willRerouteNotificationExpectation], timeout: 0.1)

        // MARK: Upon rerouting successfully...
        directionsClientSpy.fireLastCalculateCompletion(with: nil, routes: [alternateRoute], error: nil)

        // MARK: It tells the delegate & posts a didReroute notification
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didRerouteAlong:at:proactive:)"))
        wait(for: [didRerouteNotificationExpectation], timeout: 0.1)

        // MARK: On the next call to `locationManager(_, didUpdateLocations:)`
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [testLocation])

        // MARK: It tells the delegate & posts a routeProgressDidChange notification
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didUpdate:with:rawLocation:)"))
        wait(for: [routeProgressDidChangeNotificationExpectation], timeout: 0.1)

        // MARK: It enqueues and flushes a NavigationRerouteEvent
        let expectedEventName = MMEEventTypeNavigationReroute
        let eventsManagerSpy = navigationService.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
        XCTAssertEqual(eventsManagerSpy.enqueuedEventCount(with: expectedEventName), 1)
        XCTAssertEqual(eventsManagerSpy.flushedEventCount(with: expectedEventName), 1)
    }

    func testGeneratingAnArrivalEvent() {
        let navigation = dependencies.navigationService

        let now = Date()
        let trace = Fixture.generateTrace(for: route).shiftedToPresent()
        trace.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }

        // TODO: Verify why we need a second location update when routeState == .complete to trigger `MMEEventTypeNavigationArrive`
        navigation.router!.locationManager!(navigation.locationManager,
                                            didUpdateLocations: [trace.last!.shifted(to: now + (trace.count + 1))])

        // MARK: It queues and flushes a Depart event
        let eventsManagerSpy = navigation.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEEventTypeNavigationDepart))

        // MARK: When at a valid location just before the last location
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:willArriveAt:after:distance:)"), "Pre-arrival delegate message not fired.")

        // MARK: It tells the delegate that the user did arrive
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))

        // MARK: It enqueues and flushes an arrival event
        let expectedEventName = MMEEventTypeNavigationArrive
        XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
    }

    func testNoReroutesAfterArriving() {
        let navigation = dependencies.navigationService

        // MARK: When navigation begins with a location update
        let now = Date()
        let trace = Fixture.generateTrace(for: route).shiftedToPresent()

        trace.forEach { navigation.router.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }

        let eventsManagerSpy = navigation.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEEventTypeNavigationDepart))

        // MARK: It tells the delegate that the user did arrive
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))

        // MARK: Continue off route after arrival
        let offRouteCoordinate = trace.map { $0.coordinate }.last!.coordinate(at: 200, facing: 0)
        let offRouteLocations = (0...3).map {
            CLLocation(coordinate: offRouteCoordinate, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: now + trace.count + $0)
        }

        offRouteLocations.forEach { navigation.router.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }

        // Make sure configurable delegate is called
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:shouldPreventReroutesWhenArrivingAt:)"))

        // We should not reroute here because the user has arrived.
        XCTAssertFalse(delegate.recentMessages.contains("navigationService(_:didRerouteAlong:)"))

        // It enqueues and flushes an arrival event
        let expectedEventName = MMEEventTypeNavigationArrive
        XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
    }

    func testRouteControllerDoesNotHaveRetainCycle() {
        weak var subject: RouteController? = nil

        autoreleasepool {
            let fakeDataSource = RouteControllerDataSourceFake()
            let routeController = RouteController(along: initialRoute, options: routeOptions,  directions: directionsClientSpy, dataSource: fakeDataSource)
            subject = routeController
        }

        XCTAssertNil(subject, "Expected RouteController not to live beyond autorelease pool")
    }

    func testLegacyRouteControllerDoesNotHaveRetainCycle() {
        weak var subject: RouteController? = nil

        autoreleasepool {
            let fakeDataSource = RouteControllerDataSourceFake()
            let routeController = RouteController(along: initialRoute, options: routeOptions,  directions: directionsClientSpy, dataSource: fakeDataSource)
            subject = routeController
        }

        XCTAssertNil(subject, "Expected LegacyRouteController not to live beyond autorelease pool")
    }

    func testRouteControllerDoesNotRetainDataSource() {
        weak var subject: RouterDataSource? = nil

        autoreleasepool {
            let fakeDataSource = RouteControllerDataSourceFake()
            _ = RouteController(along: initialRoute, options: routeOptions,  directions: directionsClientSpy, dataSource: fakeDataSource)
            subject = fakeDataSource
        }

        XCTAssertNil(subject, "Expected LocationManager's Delegate to be nil after RouteController Deinit")
    }

    func testCountdownTimerDefaultAndUpdate() {
        let directions = DirectionsSpy()
        let subject = MapboxNavigationService(route: initialRoute, routeOptions: routeOptions,  directions: directions)

        XCTAssert(subject.poorGPSTimer.countdownInterval == .milliseconds(2500), "Default countdown interval should be 2500 milliseconds.")

        subject.poorGPSPatience = 5.0
        XCTAssert(subject.poorGPSTimer.countdownInterval == .milliseconds(5000), "Timer should now have a countdown interval of 5000 millseconds.")
    }

    func testMultiLegRoute() {
        let route = Fixture.route(from: "multileg-route", options: NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268),
            CLLocationCoordinate2D(latitude: 47.212326, longitude: 9.512569),
        ]))
        let trace = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
        let service = dependencies.navigationService

        let routeController = service.router as! RouteController
        routeController.route = route

        for (index, location) in trace.enumerated() {
            service.locationManager!(service.locationManager, didUpdateLocations: [location])

            if index < 33 {
                XCTAssert(routeController.routeProgress.legIndex == 0)
            } else {
                XCTAssert(routeController.routeProgress.legIndex == 1)
            }
        }

        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))
    }

    func testProactiveRerouting() {
        typealias RouterComposition = Router & InternalRouter

        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])
        let route = Fixture.route(from: "DCA-Arboretum", options: options)
        let trace = Fixture.generateTrace(for: route).shiftedToPresent()
        let duration = trace.last!.timestamp.timeIntervalSince(trace.first!.timestamp)

        XCTAssert(duration > RouteControllerProactiveReroutingInterval + RouteControllerMinimumDurationRemainingForProactiveRerouting,
                  "Duration must greater than rerouting interval and minimum duration remaining for proactive rerouting")

        let directions = DirectionsSpy()
        let service = MapboxNavigationService(route: route, routeOptions: options, directions: directions)
        service.delegate = delegate
        let router = service.router!
        let locationManager = NavigationLocationManager()

        let _ = expectation(forNotification: .routeControllerDidReroute, object: router) { (notification) -> Bool in
            let isProactive = notification.userInfo![RouteController.NotificationUserInfoKey.isProactiveKey] as? Bool
            return isProactive == true
        }
        let rerouteExpectation = expectation(description: "Proactive reroute should trigger")

        for location in trace {
            service.router!.locationManager!(locationManager, didUpdateLocations: [location])

            let router = service.router! as! RouterComposition

            if router.lastRerouteLocation != nil {
                rerouteExpectation.fulfill()
                break
            }
        }

        let fasterRouteName = "DCA-Arboretum-dummy-faster-route"
        let fasterOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.878206, longitude: -77.037265),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])
        let fasterRoute = Fixture.route(from: fasterRouteName, options: fasterOptions)
        let waypointsForFasterRoute = Fixture.waypoints(from: fasterRouteName, options: fasterOptions)
        directions.fireLastCalculateCompletion(with: waypointsForFasterRoute, routes: [fasterRoute], error: nil)

        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didRerouteAlong:at:proactive:)"))

        waitForExpectations(timeout: 10)
    }

    func testUnimplementedLogging() {
        unimplementedTestLogs = []

        let options =  NavigationRouteOptions(coordinates: [
                   CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
                   CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
               ])
        let route = Fixture.route(from: "DCA-Arboretum", options: options)
        let directions = Directions(credentials: Fixture.credentials)
        let locationManager = DummyLocationManager()
        let trace = Fixture.generateTrace(for: route, speedMultiplier: 2).shiftedToPresent()

        let service = MapboxNavigationService(route: route, routeOptions: options, directions: directions, locationSource: locationManager, eventsManagerType: nil)

        let spy = EmptyNavigationServiceDelegate()
        service.delegate = spy
        service.start()

        for location in trace {
            service.locationManager(locationManager, didUpdateLocations: [location])
        }

        guard let logs = unimplementedTestLogs else {
            XCTFail("Unable to fetch logs")
            return
        }

        let ourLogs = logs.filter { $0.0 == "EmptyNavigationServiceDelegate" }

        XCTAssertEqual(ourLogs.count, 7, "Expected logs to be populated and expected number of messages sent")
        unimplementedTestLogs = nil
    }
}

class EmptyNavigationServiceDelegate: NavigationServiceDelegate {}
