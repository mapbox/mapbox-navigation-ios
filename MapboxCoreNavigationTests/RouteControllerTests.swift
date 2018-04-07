import XCTest
import MapboxDirections
import Turf
import MapboxMobileEvents
@testable import MapboxCoreNavigation

fileprivate let mbTestHeading: CLLocationDirection = 50

class RouteControllerTests: XCTestCase {

    struct Constants {
        static let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        static let accessToken = "nonsense"
    }

    let eventsManagerSpy = EventsManagerSpy()
    let directionsClientSpy = DirectionsSpy(accessToken: "garbage", host: nil)

    lazy var dependencies: (routeController: RouteController, firstLocation: CLLocation) = {
        let navigation = RouteController(along: initialRoute, directions: directionsClientSpy, locationManager: NavigationLocationManager(), eventsManager: eventsManagerSpy)
        let firstCoord = navigation.routeProgress.currentLegProgress.nearbyCoordinates.first!

        return (routeController: navigation, firstLocation: CLLocation(coordinate: firstCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date()))
    }()

    lazy var initialRoute: Route = {
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let route = Route(json: Constants.jsonRoute, waypoints: [waypoint1, waypoint2], routeOptions: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
        route.accessToken = Constants.accessToken
        return route
    }()

    lazy var alternateRoute: Route = {
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.893922, longitude: -77.023900))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.880727, longitude: -77.024888))
        let route = Route(json: Constants.jsonRoute, waypoints: [waypoint1, waypoint2], routeOptions: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
        route.accessToken = Constants.accessToken
        return route
    }()

    override func setUp() {
        super.setUp()

        eventsManagerSpy.reset()
        directionsClientSpy.reset()
    }

    func testUserIsOnRoute() {
        let navigation = dependencies.routeController
        let firstLocation = dependencies.firstLocation

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertTrue(navigation.userIsOnRoute(firstLocation), "User should be on route")
    }

    func testUserIsOffRoute() {
        let navigation = dependencies.routeController
        let firstLocation = dependencies.firstLocation

        let coordinateOffRoute = firstLocation.coordinate.coordinate(at: 100, facing: 90)
        let locationOffRoute = CLLocation(latitude: coordinateOffRoute.latitude, longitude: coordinateOffRoute.longitude)
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [locationOffRoute])
        XCTAssertFalse(navigation.userIsOnRoute(locationOffRoute), "User should be off route")
    }

    func testAdvancingToFutureStepAndNotRerouting() {
        let navigation = dependencies.routeController
        let firstLocation = dependencies.firstLocation
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertTrue(navigation.userIsOnRoute(firstLocation), "User should be on route")
        XCTAssertEqual(navigation.routeProgress.currentLegProgress.stepIndex, 0, "User is on first step")

        let futureCoordinate = navigation.routeProgress.currentLegProgress.leg.steps[2].coordinates![10]
        let futureLocation = CLLocation(latitude: futureCoordinate.latitude, longitude: futureCoordinate.longitude)

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [futureLocation])
        XCTAssertTrue(navigation.userIsOnRoute(futureLocation), "User should be on route")
        XCTAssertEqual(navigation.routeProgress.currentLegProgress.stepIndex, 2, "User should be on route and we should increment all the way to the 4th step")
    }

    func testSnappedLocation() {
        let navigation = dependencies.routeController
        let firstLocation = dependencies.firstLocation
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
    }

    func testSnappedLocationForUnqualifiedLocation() {
        let navigation = dependencies.routeController
        let firstLocation = dependencies.firstLocation
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")

        let futureCoord = Polyline(navigation.routeProgress.currentLegProgress.nearbyCoordinates).coordinateFromStart(distance: 100)!
        let futureInaccurateLocation = CLLocation(coordinate: futureCoord, altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 200, course: 0, speed: 5, timestamp: Date())

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [futureInaccurateLocation])
        XCTAssertEqual(navigation.location!.coordinate, futureInaccurateLocation.coordinate, "Inaccurate location is still snapped")
    }

    func testUserPuckShouldFaceBackwards() {
        // This route is a simple straight line: http://geojson.io/#id=gist:anonymous/64cfb27881afba26e3969d06bacc707c&map=17/37.77717/-122.46484
        let response = Fixture.JSONFromFileNamed(name: "straight-line")
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let directions = Directions(accessToken: "pk.feedCafeDeadBeefBadeBede")
        let route = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], routeOptions: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))

        route.accessToken = "foo"
        let navigation = RouteController(along: route, directions: directions)
        let firstCoord = navigation.routeProgress.currentLegProgress.nearbyCoordinates.first!
        let firstLocation = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        let coordNearStart = Polyline(navigation.routeProgress.currentLegProgress.nearbyCoordinates).coordinateFromStart(distance: 10)!

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])

        // We're now 10 meters away from the last coord, looking at the start.
        // Basically, simulating moving backwards.
        let directionToStart = coordNearStart.direction(to: firstCoord)
        let facingTowardsStartLocation = CLLocation(coordinate: coordNearStart, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: directionToStart, speed: 0, timestamp: Date())

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [facingTowardsStartLocation])

        // The course should not be the interpolated course, rather the raw course.
        XCTAssertEqual(directionToStart, navigation.location!.course, "The course should be the raw course and not an interpolated course")
        XCTAssertFalse(facingTowardsStartLocation.shouldSnap(toRouteWith: facingTowardsStartLocation.interpolatedCourse(along: navigation.routeProgress.currentLegProgress.nearbyCoordinates)!, distanceToFirstCoordinateOnLeg: facingTowardsStartLocation.distance(from: firstLocation)), "Should not snap")
    }

    func testLocationShouldUseHeading() {
        let navigation = dependencies.routeController
        let firstLocation = dependencies.firstLocation
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])

        XCTAssertEqual(navigation.location!.course, firstLocation.course, "Course should be using course")

        let invalidCourseLocation = CLLocation(coordinate: firstLocation.coordinate, altitude: firstLocation.altitude, horizontalAccuracy: firstLocation.horizontalAccuracy, verticalAccuracy: firstLocation.verticalAccuracy, course: -1, speed: firstLocation.speed, timestamp: firstLocation.timestamp)

        let heading = CLHeading(heading: mbTestHeading, accuracy: 1)!

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [invalidCourseLocation])
        navigation.locationManager(navigation.locationManager, didUpdateHeading: heading)

        XCTAssertEqual(navigation.location!.course, mbTestHeading, "Course should be using bearing")
    }

    // MARK: - Events & Delegation

    func testReroutingFromALocationSendsEvents() {
        let routeController = dependencies.routeController
        let testLocation = dependencies.firstLocation

        let delegate = RouteControllerDelegateSpy()
        routeController.delegate = delegate

        let willRerouteNotificationExpectation = expectation(forNotification: .routeControllerWillReroute, object: routeController) { (notification) -> Bool in
            let fromLocation = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as? CLLocation
            return fromLocation == testLocation
        }

        let didRerouteNotificationExpectation = expectation(forNotification: .routeControllerDidReroute, object: routeController, handler: nil)

        let routeProgressDidChangeNotificationExpectation = expectation(forNotification: .routeControllerProgressDidChange, object: routeController) { (notification) -> Bool in
            let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as? CLLocation
            let rawLocation = notification.userInfo![RouteControllerNotificationUserInfoKey.rawLocationKey] as? CLLocation
            let _ = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress

            return location == rawLocation
        }

        // MARK: When told to re-route from location -- `reroute(from:)`
        routeController.reroute(from: testLocation)

        // MARK: it tells the delegate & posts a willReroute notification
        XCTAssertTrue(delegate.recentMessages.contains("routeController(_:willRerouteFrom:)"))
        wait(for: [willRerouteNotificationExpectation], timeout: 0.1)

        // MARK: Upon rerouting successfully...
        directionsClientSpy.fireLastCalculateCompletion(with: nil, routes: [alternateRoute], error: nil)

        // MARK: It tells the delegate & posts a didReroute notification
        XCTAssertTrue(delegate.recentMessages.contains("routeController(_:didRerouteAlong:)"))
        wait(for: [didRerouteNotificationExpectation], timeout: 0.1)

        // MARK: On the next call to `locationManager(_, didUpdateLocations:)`
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [testLocation])

        // MARK: It tells the delegate & posts a routeProgressDidChange notification
        XCTAssertTrue(delegate.recentMessages.contains("routeController(_:didUpdate:)"))
        wait(for: [routeProgressDidChangeNotificationExpectation], timeout: 0.1)

        // MARK: It enqueues and flushes a NavigationRerouteEvent
        let expectedEventName = MMEEventTypeNavigationReroute
        XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
        XCTAssertEqual(eventsManagerSpy.enqueuedEventCount(with: expectedEventName), 1)
        XCTAssertEqual(eventsManagerSpy.flushedEventCount(with: expectedEventName), 1)
    }

    // MARK: Failing to get directions from location
    // TODO: it tells the delegate
    // TODO: it logs the telemetry event
    // TODO: it posts a notification with the error (do we keep this after clarifying the event tracking

    // MARK: Checking for a faster route
    // getDirections, if a bunch of checks are met (refactoring oppty), schenanigans
    // TODO: it sets routeProgress & all that
    // TODO: it tells the delegate
    // TODO: major refactoring opportunity, it calls didReroute with a mock Notification, does not post

    // MARK: more tests
    // TODO: test feedback event mutation workflow
    // TODO: test & refactor the mutation of the re-route events
    // TODO: what about SessionState?

    // MARK: When route progress changes (triggered in locationManager(didUpdateLocations:))
    // TODO: it posts a routeControllerProgressDidChange notification
    
}
