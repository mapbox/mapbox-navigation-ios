import XCTest
import MapboxDirections
import Turf
import MapboxMobileEvents
@testable import MapboxCoreNavigation

fileprivate let mbTestHeading: CLLocationDirection = 50

class EventsManagerSpy: EventsManager {
    override var manager: MMEEventsManager {
        get {
            return spy
        }
        set {
            fatalError("Don't do this")
        }
    }
    
    var spy: MMEEventsManagerSpy = MMEEventsManagerSpy()
    func reset() {
        spy.reset()
    }
}

class NavigationServiceTests: XCTestCase {

    struct Constants {
        static let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        static let accessToken = "nonsense"
    }

    var eventsManagerSpy: EventsManagerSpy!
    let directionsClientSpy = DirectionsSpy(accessToken: "garbage", host: nil)
    let delegate = NavigationServiceDelegateSpy()

    typealias RouteLocations = (firstLocation: CLLocation, penultimateLocation: CLLocation, lastLocation: CLLocation)

    lazy var dependencies: (navigationService: NavigationService, routeLocations: RouteLocations, eventSpy: EventsManagerSpy) = {
//        let eventsManager = EventsManager(dataSource: promise, accessToken: initialRoute.accessToken)
//        eventsManager.manager = eventsManagerSpy
        let navigationService = MapboxNavigationService(route: initialRoute, directions: directionsClientSpy, eventsManagerType: EventsManagerSpy.self)
        navigationService.delegate = delegate


        let legProgress: RouteLegProgress = navigationService.router.routeProgress.currentLegProgress

        let firstCoord = legProgress.nearbyCoordinates.first!
        let firstLocation = CLLocation(coordinate: firstCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

        let remainingStepCount = legProgress.remainingSteps.count
        let penultimateCoord = legProgress.remainingSteps[remainingStepCount - 2].coordinates!.first!
        let penultimateLocation = CLLocation(coordinate: penultimateCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

        let lastCoord = legProgress.remainingSteps.last!.coordinates!.first!
        let lastLocation = CLLocation(coordinate: lastCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date())

        let routeLocations = RouteLocations(firstLocation, penultimateLocation, lastLocation)

        return (navigationService: navigationService, routeLocations: routeLocations, eventSpy: navigationService.eventsManager as! EventsManagerSpy)
    }()

    lazy var initialRoute: Route = {
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let options = NavigationRouteOptions(waypoints: [waypoint1, waypoint2])
        options.shapeFormat = .polyline
        let route = Route(json: Constants.jsonRoute, waypoints: [waypoint1, waypoint2], options: options)
        route.accessToken = Constants.accessToken
        return route
    }()

    lazy var alternateRoute: Route = {
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.893922, longitude: -77.023900))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.880727, longitude: -77.024888))
        let options = NavigationRouteOptions(waypoints: [waypoint1, waypoint2])
        options.shapeFormat = .polyline
        let route = Route(json: Constants.jsonRoute, waypoints: [waypoint1, waypoint2], options: options)
        route.accessToken = Constants.accessToken
        return route
    }()

    override func setUp() {
        super.setUp()

        dependencies.eventSpy.reset()
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
        let firstLocation = dependencies.routeLocations.firstLocation

        let coordinateOffRoute = firstLocation.coordinate.coordinate(at: 100, facing: 90)
        let locationOffRoute = CLLocation(latitude: coordinateOffRoute.latitude, longitude: coordinateOffRoute.longitude)
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [locationOffRoute])
        XCTAssertFalse(navigation.router.userIsOnRoute(locationOffRoute), "User should be off route")
    }

    func testAdvancingToFutureStepAndNotRerouting() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertTrue(navigation.router.userIsOnRoute(firstLocation), "User should be on route")
        XCTAssertEqual(navigation.router.routeProgress.currentLegProgress.stepIndex, 0, "User is on first step")

        let futureCoordinate = navigation.router.routeProgress.currentLegProgress.leg.steps[2].coordinates![10]
        let futureLocation = CLLocation(latitude: futureCoordinate.latitude, longitude: futureCoordinate.longitude)

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [futureLocation])
        XCTAssertTrue(navigation.router.userIsOnRoute(futureLocation), "User should be on route")
        XCTAssertEqual(navigation.router.routeProgress.currentLegProgress.stepIndex, 2, "User should be on route and we should increment all the way to the 4th step")
    }

    func testSnappedLocation() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.router.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
    }
    
    func testSnappedAtEndOfStepLocationWhenMovingSlowly() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.router.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
        
        let firstCoordinateOnUpcomingStep = navigation.router.routeProgress.currentLegProgress.upComingStep!.coordinates!.first!
        let firstLocationOnNextStepWithNoSpeed = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, course: 10, speed: 0, timestamp: Date())
        
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithNoSpeed])
        XCTAssertEqual(navigation.router.location!.coordinate, navigation.router.routeProgress.currentLegProgress.currentStep.coordinates!.last!, "When user is not moving, snap to current leg only")
        
        let firstLocationOnNextStepWithSpeed = CLLocation(coordinate: firstCoordinateOnUpcomingStep, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, course: 10, speed: 5, timestamp: Date())
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocationOnNextStepWithSpeed])
        XCTAssertEqual(navigation.router.location!.coordinate, firstCoordinateOnUpcomingStep, "User is snapped to upcoming step when moving")
    }
    
    func testSnappedAtEndOfStepLocationWhenCourseIsSimilar() {
        let navigation = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        
        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.router.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
        
        let firstCoordinateOnUpcomingStep = navigation.router.routeProgress.currentLegProgress.upComingStep!.coordinates!.first!
        
        let finalHeading = navigation.router.routeProgress.currentLegProgress.upComingStep!.finalHeading!
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

        let futureCoord = Polyline(navigation.router.routeProgress.currentLegProgress.nearbyCoordinates).coordinateFromStart(distance: 100)!
        let futureInaccurateLocation = CLLocation(coordinate: futureCoord, altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 200, course: 0, speed: 5, timestamp: Date())

        navigation.locationManager!(navigation.locationManager, didUpdateLocations: [futureInaccurateLocation])
        XCTAssertEqual(navigation.router.location!.coordinate, futureInaccurateLocation.coordinate, "Inaccurate location is still snapped")
    }

    func testUserPuckShouldFaceBackwards() {
        // This route is a simple straight line: http://geojson.io/#id=gist:anonymous/64cfb27881afba26e3969d06bacc707c&map=17/37.77717/-122.46484
        let response = Fixture.JSONFromFileNamed(name: "straight-line")
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let directions = Directions(accessToken: "pk.feedCafeDeadBeefBadeBede")
        let route = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], options: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))

        route.accessToken = "foo"
        let navigation = MapboxNavigationService(route: route, directions: directions)
        let router = navigation.router!
        let firstCoord = router.routeProgress.currentLegProgress.nearbyCoordinates.first!
        let firstLocation = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        let coordNearStart = Polyline(router.routeProgress.currentLegProgress.nearbyCoordinates).coordinateFromStart(distance: 10)!

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])

        // We're now 10 meters away from the last coord, looking at the start.
        // Basically, simulating moving backwards.
        let directionToStart = coordNearStart.direction(to: firstCoord)
        let facingTowardsStartLocation = CLLocation(coordinate: coordNearStart, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: directionToStart, speed: 0, timestamp: Date())

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [facingTowardsStartLocation])

        // The course should not be the interpolated course, rather the raw course.
        XCTAssertEqual(directionToStart, router.location!.course, "The course should be the raw course and not an interpolated course")
        XCTAssertFalse(facingTowardsStartLocation.shouldSnap(toRouteWith: facingTowardsStartLocation.interpolatedCourse(along: router.routeProgress.currentLegProgress.nearbyCoordinates)!, distanceToFirstCoordinateOnLeg: facingTowardsStartLocation.distance(from: firstLocation)), "Should not snap")
    }

    func testLocationShouldUseHeading() {
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

        let service = MapboxNavigationService(route: initialRoute, directions: directionsClientSpy, locationSource: NavigationLocationManager(), eventsManagerType: EventsManagerSpy.self)
        let spyManager = service.eventsManager as! EventsManagerSpy
        XCTAssertTrue(spyManager.spy.hasFlushedEvent(with: MMEEventTypeAppUserTurnstile))
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

            return location == rawLocation
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
        let spyManager = navigationService.eventsManager as! EventsManagerSpy
        XCTAssertTrue(spyManager.spy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(spyManager.spy.hasFlushedEvent(with: expectedEventName))
        XCTAssertEqual(spyManager.spy.enqueuedEventCount(with: expectedEventName), 1)
        XCTAssertEqual(spyManager.spy.flushedEventCount(with: expectedEventName), 1)
    }

    func testGeneratingAnArrivalEvent() {
        let navigationService = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        let penultimateLocation = dependencies.routeLocations.penultimateLocation
        let lastLocation = dependencies.routeLocations.lastLocation

        // MARK: When navigation begins with a location update
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [firstLocation])

        // MARK: It queues and flushes a Depart event
        let spyManager = navigationService.eventsManager as! EventsManagerSpy
        XCTAssertTrue(spyManager.spy.hasFlushedEvent(with: MMEEventTypeNavigationDepart))
        // TODO: should there be a delegate message here as well?

        // MARK: When at a valid location just before the last location (should this really be necessary?)
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [penultimateLocation])

        // MARK: When navigation continues with a location update to the last location
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [lastLocation])

        // MARK: And then navigation continues with another location update at the last location
        let currentLocation = navigationService.router.location!
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [currentLocation])

        // MARK: It tells the delegate that the user did arrive
    XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))

        // MARK: It enqueues and flushes an arrival event
        let expectedEventName = MMEEventTypeNavigationArrive
        XCTAssertTrue(spyManager.spy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(spyManager.spy.hasFlushedEvent(with: expectedEventName))
    }
    
    func testNoReroutesAfterArriving() {
        let navigationService = dependencies.navigationService
        let firstLocation = dependencies.routeLocations.firstLocation
        let penultimateLocation = dependencies.routeLocations.penultimateLocation
        let lastLocation = dependencies.routeLocations.lastLocation

        // MARK: When navigation begins with a location update
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [firstLocation])
        
        // MARK: It queues and flushes a Depart event
        let spyManager = navigationService.eventsManager as! EventsManagerSpy
        XCTAssertTrue(spyManager.spy.hasFlushedEvent(with: MMEEventTypeNavigationDepart))
        // TODO: should there be a delegate message here as well?
        
        // MARK: When at a valid location just before the last location (should this really be necessary?)
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [penultimateLocation])

        // MARK: When navigation continues with a location update to the last location
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [lastLocation])
        
        // MARK: And then navigation continues with another location update at the last location
        let currentLocation = navigationService.router.location!
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [currentLocation])
        
        // MARK: It tells the delegate that the user did arrive
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))
        
        // Find a location that is very far off route
        let locationBeyondRoute = navigationService.router.location!.coordinate.coordinate(at: 2000, facing: 0)
        navigationService.locationManager!(navigationService.locationManager, didUpdateLocations: [CLLocation(latitude: locationBeyondRoute.latitude, longitude: locationBeyondRoute.latitude)])
        
        // Make sure configurable delegate is called
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:shouldPreventReroutesWhenArrivingAt:)"))
        
        // We should not reroute here because the user has arrived.
        XCTAssertFalse(delegate.recentMessages.contains("navigationService(_:didRerouteAlong:)"))
        
        // MARK: It enqueues and flushes an arrival event
        let expectedEventName = MMEEventTypeNavigationArrive
        XCTAssertTrue(spyManager.spy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(spyManager.spy.hasFlushedEvent(with: expectedEventName))
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
}

class RouteControllerDataSourceFake: RouterDataSource {
    
    let manager = NavigationLocationManager()
    
    var location: CLLocation? {
        return manager.location
    }
    
    var locationProvider: NavigationLocationManager.Type {
        return type(of: manager)
    }
    
    
}
