import XCTest
import MapboxDirections
import Turf
import MapboxMobileEvents
import os.log
@testable import TestHelper
@testable import MapboxCoreNavigation

fileprivate let mbTestHeading: CLLocationDirection = 50

// minimum distance threshold between two locations (in meters)
fileprivate let distanceThreshold: CLLocationDistance = 2

// minimum threshold for both latitude and longitude between two coordinates
fileprivate let coordinateThreshold: CLLocationDistance = 0.0005

class NavigationServiceTests: XCTestCase {
    var eventsManagerSpy: NavigationEventsManagerSpy!
    let directionsClientSpy = DirectionsSpy()
    let delegate = NavigationServiceDelegateSpy()

    typealias RouteLocations = (firstLocation: CLLocation, penultimateLocation: CLLocation, lastLocation: CLLocation)

    lazy var dependencies: (navigationService: NavigationService, routeLocations: RouteLocations) = {
        let navigationService = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions, directions: directionsClientSpy, eventsManagerType: NavigationEventsManagerSpy.self, simulating: .never)
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
        
        // Create list of 3 coordinates which are located on actual route
        let coordinatesOnRoute = route.shape!.coordinates.prefix(3)
        let now = Date()
        let locationsOnRoute = coordinatesOnRoute.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: now + $0.offset)
        }
        
        // Iterate over each location on the route and simulate location update
        locationsOnRoute.forEach {
            navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0])
            
            // Verify whether current location is located on the route
            XCTAssertTrue(navigation.router.userIsOnRoute($0), "User should be on the route")
        }
        
        // Create list of 3 coordinates: all coordinates have distance component slightly changed, which means that they're off the route
        let coordinatesOffRoute: [CLLocationCoordinate2D] = (0...2).map { _ in locationsOnRoute.first!.coordinate.coordinate(at: 100, facing: 90) }
        let locationsOffRoute = coordinatesOffRoute.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: now + locationsOnRoute.count + $0.offset)
        }
        
        // Iterate over the list of locations which are off the route and verify whether all locations except first one are off the route.
        // Even though first location is off the route as per navigation native logic it sometimes can return tracking route state
        // even if location is visually off-route.
        locationsOffRoute.enumerated().forEach {
            navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0.element])
            
            if ($0.offset == 0) {
                XCTAssertTrue(navigation.router.userIsOnRoute($0.element), "For the first coordinate user is still on the route")
            } else {
                XCTAssertFalse(navigation.router.userIsOnRoute($0.element), "User should be off route")
            }
        }
    }

    func testNotReroutingForAllSteps() {
        let navigation = dependencies.navigationService
        let route = navigation.route
        
        route.legs[0].steps.enumerated().forEach {
            let stepCoordinates = $0.element.shape!.coordinates
            let now = Date()
            let stepLocations = stepCoordinates.enumerated().map {
                CLLocation(coordinate: $0.element,
                           altitude: -1,
                           horizontalAccuracy: 10,
                           verticalAccuracy: -1,
                           course: -1,
                           speed: 10,
                           timestamp: now + $0.offset)
            }
            
            stepLocations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
            
            XCTAssertTrue(navigation.router.userIsOnRoute(stepLocations.last!), "User should be on route")
        }
    }

    func testSnappedAtEndOfStepLocationWhenMovingSlowly() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        
        // Check whether snapped location is within allowed threshold
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstLocation.coordinate.latitude, accuracy: coordinateThreshold, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstLocation.coordinate.longitude, accuracy: coordinateThreshold, "Longitudes should be almost equal")

        // Check whether distance (in meters) between snapped location and first location on a route is within allowed threshold
        var distance = navigation.router.location!.distance(from: firstLocation)
        XCTAssertLessThan(distance, distanceThreshold)

        let firstCoordinateOnUpcomingStep = navigation.router.routeProgress.currentLegProgress.upcomingStep!.shape!.coordinates.first!
        let firstLocationOnNextStepWithNoSpeed = CLLocation(coordinate: firstCoordinateOnUpcomingStep,
                                                            altitude: 0,
                                                            horizontalAccuracy: 10,
                                                            verticalAccuracy: 10,
                                                            course: 10,
                                                            speed: 0,
                                                            timestamp: Date())

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithNoSpeed])
        
        // When user is not moving (location is changed to first one in upcoming step, but neither speed nor timestamp were changed)
        // navigation native will snap to current location in current step
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstLocation.coordinate.latitude, accuracy: coordinateThreshold, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstLocation.coordinate.longitude, accuracy: coordinateThreshold, "Longitudes should be almost equal")
        distance = navigation.router.location!.distance(from: firstLocation)
        XCTAssertLessThan(distance, distanceThreshold)
        
        let firstLocationOnNextStepWithSpeed = CLLocation(coordinate: firstCoordinateOnUpcomingStep,
                                                          altitude: 0,
                                                          horizontalAccuracy: 10,
                                                          verticalAccuracy: 10,
                                                          course: 10,
                                                          speed: 5,
                                                          timestamp: Date() + 5)
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithSpeed])

        // User is snapped to upcoming step when moving
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstCoordinateOnUpcomingStep.latitude, accuracy: coordinateThreshold, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstCoordinateOnUpcomingStep.longitude, accuracy: coordinateThreshold, "Longitudes should be almost equal")
        distance = navigation.router.location!.distance(from: firstLocationOnNextStepWithSpeed)
        XCTAssertLessThan(distance, distanceThreshold)
    }

    func testSnappedAtEndOfStepLocationWhenCourseIsSimilar() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        
        // Check whether snapped location is within allowed threshold
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstLocation.coordinate.latitude, accuracy: coordinateThreshold, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstLocation.coordinate.longitude, accuracy: coordinateThreshold, "Longitudes should be almost equal")
        
        // Check whether distance (in meters) between snapped location and first location on a route is within allowed threshold
        var distance = navigation.router.location!.distance(from: firstLocation)
        XCTAssertLessThan(distance, distanceThreshold)
        
        let firstCoordinateOnUpcomingStep = navigation.router.routeProgress.currentLegProgress.upcomingStep!.shape!.coordinates.first!

        let finalHeading = navigation.router.routeProgress.currentLegProgress.upcomingStep!.finalHeading!
        let firstLocationOnNextStepWithDifferentCourse = CLLocation(coordinate: firstCoordinateOnUpcomingStep,
                                                                    altitude: 0,
                                                                    horizontalAccuracy: 30,
                                                                    verticalAccuracy: 10,
                                                                    course: (finalHeading + 180).truncatingRemainder(dividingBy: 360),
                                                                    speed: 5,
                                                                    timestamp: Date() + 5)

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithDifferentCourse])

        let lastCoordinateOnCurrentStep = navigation.router.routeProgress.currentLegProgress.currentStep.shape!.coordinates.last!

        // When user's course is dissimilar from the finalHeading, they should not snap to upcoming step
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, lastCoordinateOnCurrentStep.latitude, accuracy: coordinateThreshold, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, lastCoordinateOnCurrentStep.longitude, accuracy: coordinateThreshold, "Longitudes should be almost equal")
        distance = navigation.router.location!.distance(from: CLLocation(latitude: lastCoordinateOnCurrentStep.latitude, longitude: lastCoordinateOnCurrentStep.longitude))
        XCTAssertLessThan(distance, distanceThreshold)
        
        let firstLocationOnNextStepWithCorrectCourse = CLLocation(coordinate: firstCoordinateOnUpcomingStep,
                                                                  altitude: 0,
                                                                  horizontalAccuracy: 30,
                                                                  verticalAccuracy: 10,
                                                                  course: finalHeading,
                                                                  speed: 0,
                                                                  timestamp: Date())
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithCorrectCourse])
        
        // User is snapped to upcoming step when their course is similar to the final heading
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstCoordinateOnUpcomingStep.latitude, accuracy: coordinateThreshold, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstCoordinateOnUpcomingStep.longitude, accuracy: coordinateThreshold, "Longitudes should be almost equal")
        distance = navigation.router.location!.distance(from: firstLocationOnNextStepWithCorrectCourse)
        XCTAssertLessThan(distance, distanceThreshold)
    }

    func testSnappedLocationForUnqualifiedLocation() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        
        // Check whether snapped location is within allowed threshold
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstLocation.coordinate.latitude, accuracy: coordinateThreshold, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstLocation.coordinate.longitude, accuracy: coordinateThreshold, "Longitudes should be almost equal")
        
        // Check whether distance (in meters) between snapped location and first location on a route is within allowed threshold
        var distance = navigation.router.location!.distance(from: firstLocation)
        XCTAssertLessThan(distance, distanceThreshold)

        let futureCoordinate = navigation.router.routeProgress.nearbyShape.coordinateFromStart(distance: 100)!
        let futureInaccurateLocation = CLLocation(coordinate: futureCoordinate,
                                                  altitude: 0,
                                                  horizontalAccuracy: 0,
                                                  verticalAccuracy: 0,
                                                  course: 0,
                                                  speed: 0,
                                                  timestamp: Date() + 5)
        
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [futureInaccurateLocation])

        // Inaccurate location should still be snapped
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, futureInaccurateLocation.coordinate.latitude, accuracy: coordinateThreshold, "Latitudes should be almost equal")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, futureInaccurateLocation.coordinate.longitude, accuracy: coordinateThreshold, "Longitudes should be almost equal")
        distance = navigation.router.location!.distance(from: futureInaccurateLocation)
        XCTAssertLessThan(distance, distanceThreshold)
    }

    func testLocationCourseShouldNotChange() {
        // This route is a simple straight line: http://geojson.io/#id=gist:anonymous/64cfb27881afba26e3969d06bacc707c&map=17/37.77717/-122.46484
        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.77735, longitude: -122.461465),
            CLLocationCoordinate2D(latitude: 37.777016, longitude: -122.468832),
        ])
        let route = Fixture.route(from: "straight-line", options: options)
        let navigationService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: options, directions: DirectionsSpy())
        let router = navigationService.router!
        let firstCoordinate = router.routeProgress.nearbyShape.coordinates.first!
        let firstLocation = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
        let coordinateNearStart = router.routeProgress.nearbyShape.coordinateFromStart(distance: 10)!
        
        navigationService.locationManager(navigationService.locationManager, didUpdateLocations: [firstLocation])
        
        // As per navigation native logic location course will be set to the course of the road,
        // so providing locations with different course will not affect anything.
        let directionToStart = coordinateNearStart.direction(to: firstCoordinate)
        let facingTowardsStartLocation = CLLocation(coordinate: coordinateNearStart,
                                                    altitude: 0,
                                                    horizontalAccuracy: 0,
                                                    verticalAccuracy: 0,
                                                    course: directionToStart,
                                                    speed: 0,
                                                    timestamp: Date())
        
        navigationService.locationManager(navigationService.locationManager, didUpdateLocations: [facingTowardsStartLocation])
        
        // Instead of raw course navigator will return interpolated course (course of the road).
        let interpolatedCourse = facingTowardsStartLocation.interpolatedCourse(along: router.routeProgress.nearbyShape)!
        XCTAssertEqual(Int(interpolatedCourse), Int(router.location!.course), "Interpolated course and course provided by navigation native should be almost equal.")
        XCTAssertFalse(facingTowardsStartLocation.shouldSnap(toRouteWith: interpolatedCourse,
                                                             distanceToFirstCoordinateOnLeg: facingTowardsStartLocation.distance(from: firstLocation)), "Should not snap")
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

        let service = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions, directions: directionsClientSpy, locationSource: NavigationLocationManager(), eventsManagerType: NavigationEventsManagerSpy.self)
        let eventsManagerSpy = service.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEEventTypeAppUserTurnstile))
    }

    func testReroutingFromLocationUpdatesSimulatedLocationSource() {
        let navigationService = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions,  directions: directionsClientSpy, eventsManagerType: NavigationEventsManagerSpy.self, simulating: .always)
        navigationService.delegate = delegate
        let router = navigationService.router!

        navigationService.eventsManager.delaysEventFlushing = false
        navigationService.start()

        let eventsManagerSpy = navigationService.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: NavigationEventTypeRouteRetrieval))

        router.indexedRoute = (alternateRoute, 0)

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

            XCTAssertTrue(location!.distance(from: rawLocation!) <= distanceThreshold)

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
            let routeController = RouteController(along: initialRoute, routeIndex: 0, options: routeOptions,  directions: directionsClientSpy, dataSource: fakeDataSource)
            subject = routeController
        }

        XCTAssertNil(subject, "Expected RouteController not to live beyond autorelease pool")
    }

    func testLegacyRouteControllerDoesNotHaveRetainCycle() {
        weak var subject: RouteController? = nil

        autoreleasepool {
            let fakeDataSource = RouteControllerDataSourceFake()
            let routeController = RouteController(along: initialRoute, routeIndex: 0, options: routeOptions,  directions: directionsClientSpy, dataSource: fakeDataSource)
            subject = routeController
        }

        XCTAssertNil(subject, "Expected LegacyRouteController not to live beyond autorelease pool")
    }

    func testRouteControllerDoesNotRetainDataSource() {
        weak var subject: RouterDataSource? = nil

        autoreleasepool {
            let fakeDataSource = RouteControllerDataSourceFake()
            _ = RouteController(along: initialRoute, routeIndex: 0, options: routeOptions, directions: directionsClientSpy, dataSource: fakeDataSource)
            subject = fakeDataSource
        }

        XCTAssertNil(subject, "Expected LocationManager's Delegate to be nil after RouteController Deinit")
    }

    func testCountdownTimerDefaultAndUpdate() {
        let directions = DirectionsSpy()
        let subject = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions,  directions: directions)

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

        let navigationService = dependencies.navigationService
        let routeController = navigationService.router as! RouteController
        routeController.indexedRoute = (route, 0)
        let trace = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
        
        for (index, location) in trace.enumerated() {
            navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [location])

            if index < 32 {
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
        let service = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: options, directions: directions)
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

        let service = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: options, directions: directions, locationSource: locationManager, eventsManagerType: nil)

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
