import XCTest
import MapboxDirections
import Turf
import MapboxMobileEvents
@testable import TestHelper
@testable import MapboxCoreNavigation

fileprivate let mbTestHeading: CLLocationDirection = 50

class NavigationServiceTests: XCTestCase {
    
    var eventsManagerSpy: NavigationEventsManagerSpy!
    let directionsClientSpy = DirectionsSpy(accessToken: "garbage", host: nil)
    let delegate = NavigationServiceDelegateSpy()
    
    typealias RouteLocations = (firstLocation: CLLocation, penultimateLocation: CLLocation, lastLocation: CLLocation)
    
    lazy var dependencies: (navigationService: NavigationService, routeLocations: RouteLocations) = {
        let navigationService = MapboxNavigationService(route: initialRoute, directions: directionsClientSpy, eventsManagerType: NavigationEventsManagerSpy.self, simulating: .never)
        navigationService.delegate = delegate
        
        let legProgress: RouteLegProgress = navigationService.router.routeProgress.currentLegProgress
        
        let firstCoord = navigationService.router.routeProgress.nearbyCoordinates.first!
        let firstLocation = CLLocation(coordinate: firstCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())
        
        let remainingSteps = legProgress.remainingSteps
        let penultimateCoord = legProgress.remainingSteps[4].coordinates!.first!
        let penultimateLocation = CLLocation(coordinate: penultimateCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())
        
        let lastCoord = legProgress.remainingSteps.last!.coordinates!.first!
        let lastLocation = CLLocation(coordinate: lastCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())
        
        let routeLocations = RouteLocations(firstLocation, penultimateLocation, lastLocation)
        
        return (navigationService: navigationService, routeLocations: routeLocations)
    }()
    
    let initialRoute = Fixture.route(from: "routeWithInstructions")
    
    let alternateRoute = Fixture.route(from: "routeWithInstructions")
    
    override func setUp() {
        super.setUp()
        
        directionsClientSpy.reset()
        delegate.reset()
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
        
        let coordinates = route.coordinates!.prefix(3)
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: Date().addingTimeInterval(TimeInterval($0.offset))) }
        
        locations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        
        XCTAssertTrue(navigation.router.userIsOnRoute(locations.last!), "User should be on route")
        
        let coordinatesOffRoute: [CLLocationCoordinate2D] = (0...3).map { _ in locations.first!.coordinate.coordinate(at: 100, facing: 90) }
        let locationsOffRoute = coordinatesOffRoute.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10,
                       verticalAccuracy: -1, course: -1, speed: 10,
                       timestamp: Date().addingTimeInterval(TimeInterval(locations.count + $0.offset)))
        }
        
        locationsOffRoute.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        
        XCTAssertFalse(navigation.router.userIsOnRoute(locationsOffRoute.last!), "User should be off route")
    }
    
    func testAdvancingToFutureStepAndNotRerouting() {
        let navigation = dependencies.navigationService
        let route = navigation.route
        
        let firstStepCoordinates = route.legs[0].steps[0].coordinates!
        let firstStepLocations = firstStepCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: Date().addingTimeInterval(TimeInterval($0.offset)))
        }
        
        firstStepLocations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        XCTAssertTrue(navigation.router.userIsOnRoute(firstStepLocations.last!), "User should be on route")
        XCTAssertEqual(navigation.router.routeProgress.currentLegProgress.stepIndex, 1, "User is on first step")
        
        let thirdStepCoordinates = route.legs[0].steps[2].coordinates!
        let thirdStepLocations = thirdStepCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: Date().addingTimeInterval(TimeInterval(firstStepCoordinates.count + $0.offset)))
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
        XCTAssertEqual(navigation.router.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
        
        let firstCoordinateOnUpcomingStep = navigation.router.routeProgress.currentLegProgress.upcomingStep!.coordinates!.first!
        let firstLocationOnNextStepWithNoSpeed = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, course: 10, speed: 0, timestamp: Date())
        
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithNoSpeed])
        XCTAssertEqual(navigation.router.location!.coordinate, navigation.router.routeProgress.currentLegProgress.currentStep.coordinates!.last!, "When user is not moving, snap to current leg only")
        
        let firstLocationOnNextStepWithSpeed = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, course: 10, speed: 5, timestamp: Date())
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithSpeed])
        
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, firstCoordinateOnUpcomingStep.latitude, accuracy: 0.0005, "User is snapped to upcoming step when moving")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, firstCoordinateOnUpcomingStep.longitude, accuracy: 0.0005, "User is snapped to upcoming step when moving")
    }
    
    func testSnappedAtEndOfStepLocationWhenCourseIsSimilar() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.router.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
        
        let firstCoordinateOnUpcomingStep = navigation.router.routeProgress.currentLegProgress.upcomingStep!.coordinates!.first!
        
        let finalHeading = navigation.router.routeProgress.currentLegProgress.upcomingStep!.finalHeading!
        let firstLocationOnNextStepWithDifferentCourse = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 30, verticalAccuracy: 10, course: -finalHeading, speed: 5, timestamp: Date())
        
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithDifferentCourse])
        XCTAssertEqual(navigation.router.location!.coordinate, navigation.router.routeProgress.currentLegProgress.currentStep.coordinates!.last!, "When user's course is dissimilar from the finalHeading, they should not snap to upcoming step")
        
        let firstLocationOnNextStepWithCorrectCourse = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 30, verticalAccuracy: 10, course: finalHeading, speed: 0, timestamp: Date())
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithCorrectCourse])
        XCTAssertEqual(navigation.router.location!.coordinate, firstCoordinateOnUpcomingStep, "User is snapped to upcoming step when their course is similar to the final heading")
    }
    
    func testSnappedLocationForUnqualifiedLocation() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.router.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
        
        let futureCoord = Polyline(navigation.router.routeProgress.nearbyCoordinates).coordinateFromStart(distance: 100)!
        let futureInaccurateLocation = CLLocation(coordinate: futureCoord, altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 200, course: 0, speed: 5, timestamp: Date())
        
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [futureInaccurateLocation])
        
        XCTAssertEqual(navigation.router.location!.coordinate.latitude, futureInaccurateLocation.coordinate.latitude, accuracy: 0.0005, "Inaccurate location is still snapped")
        XCTAssertEqual(navigation.router.location!.coordinate.longitude, futureInaccurateLocation.coordinate.longitude, accuracy: 0.0005, "Inaccurate location is still snapped")
        
    }
    
    func testUserPuckShouldFaceBackwards() {
        // This route is a simple straight line: http://geojson.io/#id=gist:anonymous/64cfb27881afba26e3969d06bacc707c&map=17/37.77717/-122.46484
        let directions = DirectionsSpy(accessToken: "pk.feedCafeDeadBeefBadeBede")
        let route = Fixture.route(from: "straight-line")
        
        route.accessToken = "foo"
        let navigation = MapboxNavigationService(route: route, directions: directions)
        let router = navigation.router!
        let firstCoord = router.routeProgress.nearbyCoordinates.first!
        let firstLocation = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        let coordNearStart = Polyline(router.routeProgress.nearbyCoordinates).coordinateFromStart(distance: 10)!
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        
        // We're now 10 meters away from the last coord, looking at the start.
        // Basically, simulating moving backwards.
        let directionToStart = coordNearStart.direction(to: firstCoord)
        let facingTowardsStartLocation = CLLocation(coordinate: coordNearStart, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: directionToStart, speed: 0, timestamp: Date())
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [facingTowardsStartLocation])
        
        // The course should not be the interpolated course, rather the raw course.
        XCTAssertEqual(directionToStart, router.location!.course, "The course should be the raw course and not an interpolated course")
        XCTAssertFalse(facingTowardsStartLocation.shouldSnap(toRouteWith: facingTowardsStartLocation.interpolatedCourse(along: router.routeProgress.nearbyCoordinates)!, distanceToFirstCoordinateOnLeg: facingTowardsStartLocation.distance(from: firstLocation)), "Should not snap")
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
        
        let service = MapboxNavigationService(route: initialRoute, directions: directionsClientSpy, locationSource: NavigationLocationManager(), eventsManagerType: NavigationEventsManagerSpy.self)
        let eventsManagerSpy = service.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEEventTypeAppUserTurnstile))
    }
    
    func testReroutingFromALocationSendsEvents() {
        let navigationService = dependencies.navigationService
        let router = navigationService.router!
        let testLocation = dependencies.routeLocations.firstLocation
        
        navigationService.eventsManager.delaysEventFlushing = false
        
        let willRerouteNotificationExpectation = expectation(forNotification: .routeControllerWillReroute, object: router) { (notification) -> Bool in
            let fromLocation = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as? CLLocation
            return fromLocation == testLocation
        }
        
        let didRerouteNotificationExpectation = expectation(forNotification: .routeControllerDidReroute, object: router, handler: nil)
        
        let routeProgressDidChangeNotificationExpectation = expectation(forNotification: .routeControllerProgressDidChange, object: router) { (notification) -> Bool in
            let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as? CLLocation
            let rawLocation = notification.userInfo![RouteControllerNotificationUserInfoKey.rawLocationKey] as? CLLocation
            let _ = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
            
            return location!.distance(from: rawLocation!) <= 0.0005
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
        
        let penultimateCoordinates = route.legs[0].steps[route.legs[0].steps.count-2].coordinates!
        
        let penultimateLocations = penultimateCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: Date().addingTimeInterval(TimeInterval($0.offset)))
        }
        
        penultimateLocations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        
        // MARK: It queues and flushes a Depart event
        let eventsManagerSpy = navigation.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEEventTypeNavigationDepart))
        
        // MARK: When at a valid location just before the last location
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:willArriveAt:after:distance:)"), "Pre-arrival delegate message not fired.")
        
        // MARK: It tells the delegate that the user did arrive
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))
        
        // MARK: It enqueues and flushes an arrival event
        let expectedEventName = MMEEventTypeNavigationArrive
        // TODO: Verify these events
        //XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        //XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
    }
    
    func testNoReroutesAfterArriving() {
        let navigation = dependencies.navigationService
        
        // MARK: When navigation begins with a location update
        let firstStepCoordinates = route.legs[0].steps[0].coordinates!
        let firstStepLocations = firstStepCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: Date().addingTimeInterval(TimeInterval($0.offset)))
        }
        
        firstStepLocations.forEach { navigation.router.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        
        // MARK: It queues and flushes a Depart event
        let eventsManagerSpy = navigation.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEEventTypeNavigationDepart))
        
        let penultimateCoordinates = route.legs[0].steps[route.legs[0].steps.count-2].coordinates!
        let penultimateLocations = penultimateCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: Date().addingTimeInterval(TimeInterval(firstStepCoordinates.count + $0.offset)))
        }
        
        penultimateLocations.forEach { navigation.router.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        
        // MARK: It tells the delegate that the user did arrive
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))
        
        // Find a location that is very far off route
        let offRouteCoordinate = penultimateCoordinates.last!.coordinate(at: 200, facing: 0)
        let offRouteLocations = (0...3).map {
            CLLocation(coordinate: offRouteCoordinate, altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: Date().addingTimeInterval(TimeInterval(penultimateLocations.count + $0)))
        }
        
        offRouteLocations.forEach { navigation.router.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        
        // Make sure configurable delegate is called
        // TODO: Verify why `shouldPreventReroutesWhenArrivingAt` isn't working properly
        //XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:shouldPreventReroutesWhenArrivingAt:)"))
        
        // We should not reroute here because the user has arrived.
        XCTAssertFalse(delegate.recentMessages.contains("navigationService(_:didRerouteAlong:)"))
        
        // MARK: It enqueues and flushes an arrival event
        let expectedEventName = MMEEventTypeNavigationArrive
        // TODO: Verify has hasEnqueued and hasFlushed isn't working properly
        //XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        //XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
    }
    
    //TODO: Update with NavigationService
    func testRouteControllerDoesNotHaveRetainCycle() {
        
        weak var subject: RouteController? = nil
        
        autoreleasepool {
            let fakeDataSource = RouteControllerDataSourceFake()
            let routeController = RouteController(along: initialRoute, directions: directionsClientSpy, dataSource: fakeDataSource)
            subject = routeController
        }
        
        XCTAssertNil(subject, "Expected RouteController not to live beyond autorelease pool")
    }
    
    //TODO: Update with NavigationService
    func testRouteControllerDoesNotRetainDataSource() {
        
        weak var subject: RouterDataSource? = nil
        
        autoreleasepool {
            let fakeDataSource = RouteControllerDataSourceFake()
            _ = RouteController(along: initialRoute, directions: directionsClientSpy, dataSource: fakeDataSource)
            subject = fakeDataSource
        }
        
        XCTAssertNil(subject, "Expected LocationManager's Delegate to be nil after RouteController Deinit")
    }
    
    func testCountdownTimerDefaultAndUpdate() {
        let directions = DirectionsSpy(accessToken: "pk.feedCafeDeadBeefBadeBede")
        let subject = MapboxNavigationService(route: initialRoute, directions: directions)
        
        XCTAssert(subject.poorGPSTimer.countdownInterval == .milliseconds(2500), "Default countdown interval should be 2500 milliseconds.")
        
        
        subject.poorGPSPatience = 5.0
        XCTAssert(subject.poorGPSTimer.countdownInterval == .milliseconds(5000), "Timer should now have a countdown interval of 5000 millseconds.")
    }
}
