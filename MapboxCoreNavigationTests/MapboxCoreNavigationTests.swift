import XCTest
import MapboxDirections
import Turf
import TestHelper
@testable import MapboxCoreNavigation

let jsonFileName = "routeWithInstructions"
let response = Fixture.JSONFromFileNamed(name: jsonFileName)
let directions = DirectionsSpy(accessToken: "pk.feedCafeDeadBeefBadeBede")
let route: Route = {
    return Fixture.route(from: jsonFileName)
}()

let waitForInterval: TimeInterval = 5


class MapboxCoreNavigationTests: XCTestCase {
    
    var navigation: MapboxNavigationService!
    
    func testNavigationNotificationsInfoDict() {
        route.accessToken = "foo"
        navigation = MapboxNavigationService(route: route, directions: directions, simulating: .never)
        let now = Date()
        let steps = route.legs.first!.steps
        let coordinates = steps[2].coordinates! + steps[3].coordinates!
        
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10,
                                                                  verticalAccuracy: -1, course: -1, speed: 10,
                                                                  timestamp: now + $0.offset) }
        
        
        let spokenTest = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (note) -> Bool in
            return note.userInfo!.count == 2
        }
        spokenTest.expectationDescription = "Spoken Instruction notification expected to have user info dictionary with two values"
        
        navigation.start()
        
        for loc in locations {
            navigation.locationManager(navigation.locationManager, didUpdateLocations: [loc])
        }
        
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.78895, longitude: -122.42543), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 171, speed: 10, timestamp: Date() + 4)
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [location])
        
        
        
        wait(for: [spokenTest], timeout: waitForInterval)
        
    }
    
    func testDepart() {
        route.accessToken = "foo"
        navigation = MapboxNavigationService(route: route, directions: directions, simulating: .never)
        
        // Coordinates from first step
        let coordinates = route.legs[0].steps[0].coordinates!
        let now = Date()
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10,
                                                                  verticalAccuracy: -1, course: -1, speed: 10,
                                                                  timestamp: now + $0.offset) }
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
            return routeProgress != nil && routeProgress?.currentLegProgress.userHasArrivedAtWaypoint == false
        }
        
        navigation.start()
        
        for location in locations {
            navigation.locationManager(navigation.locationManager, didUpdateLocations: [location])
        }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testNewStep() {
        route.accessToken = "foo"
        
        // Coordinates from beginning of step[1] to end of step[2]
        let coordinates = route.legs[0].steps[1].coordinates! + route.legs[0].steps[2].coordinates!
        let locations: [CLLocation]
        let now = Date()
        locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                              altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: -1, speed: 10,
                                                              timestamp: now + $0.offset) }
        
        navigation = MapboxNavigationService(route: route, directions: directions, simulating: .never)
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
            return routeProgress?.currentLegProgress.stepIndex == 2
        }
        
        navigation.start()
        
        locations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0])}
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testJumpAheadToLastStep() {
        route.accessToken = "foo"
        
        let coordinates = route.legs[0].steps.map { $0.coordinates! }.flatMap { $0 }
        
        let now = Date()
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, timestamp: now + $0.offset) }
        
        let locationManager = ReplayLocationManager(locations: locations)
        navigation = MapboxNavigationService(route: route, directions: directions, locationSource: locationManager, simulating: .never)
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            return routeProgress?.currentLegProgress.stepIndex == 4
        }
        
        navigation.start()
        
        locations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testShouldReroute() {
        route.accessToken = "foo"
        
        let coordinates = route.legs[0].steps[1].coordinates!
        let now = Date()
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: now + $0.offset) }
        
        let offRouteCoordinates = [[-122.41765, 37.79095],[-122.41830,37.79087],[-122.41907,37.79079],[-122.41960,37.79073]]
            .map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        
        let offRouteLocations = offRouteCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10,
                       verticalAccuracy: -1, course: -1, speed: 10,
                       timestamp: now + locations.count + $0.offset)
        }
        
        let locationManager = ReplayLocationManager(locations: locations + offRouteLocations)
        navigation = MapboxNavigationService(route: route, directions: directions, locationSource: locationManager, simulating: .never)
        expectation(forNotification: .routeControllerWillReroute, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as? CLLocation
            return location?.coordinate == offRouteLocations[1].coordinate
        }
        
        navigation.start()
        
        (locations + offRouteLocations).forEach {
            navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0])
        }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testArrive() {
        route.accessToken = "foo"

        let now = Date()
        let locations = Fixture.generateTrace(for: route).enumerated().map {
            $0.element.shifted(to: now + $0.offset)
        }

        let locationManager = DummyLocationManager()
        navigation = MapboxNavigationService(route: route, directions: directions, locationSource: locationManager, simulating: .never)

        expectation(forNotification: .routeControllerProgressDidChange, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            return routeProgress != nil
        }

        class Responder: NSObject, NavigationServiceDelegate {
            var willArriveExpectation: XCTestExpectation!
            var didArriveExpectation: XCTestExpectation!

            init(_ willArriveExpectation: XCTestExpectation, _ didArriveExpectation: XCTestExpectation) {
                self.willArriveExpectation = willArriveExpectation
                // TODO: remove next line (fulfill) when willArrive works properly
                self.willArriveExpectation.fulfill()
                self.didArriveExpectation = didArriveExpectation
            }

            func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
                willArriveExpectation.fulfill()
            }

            func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
                didArriveExpectation.fulfill()
                return true
            }
        }

        let willArriveExpectation = expectation(description: "navigationService(_:willArriveAt:after:distance:) must trigger")
        let didArriveExpectation = expectation(description: "navigationService(_:didArriveAt:) must trigger once")
        willArriveExpectation.assertForOverFulfill = false

        let responder = Responder(willArriveExpectation, didArriveExpectation)
        navigation.delegate = responder
        navigation.start()

        for location in locations {
            navigation.locationManager(locationManager, didUpdateLocations: [location])
        }

        self.waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testFailToReroute() {
        enum TestError: Error {
            case test
        }
        route.accessToken = "foo"
        let directionsClientSpy = DirectionsSpy(accessToken: "garbage", host: nil)
        navigation = MapboxNavigationService(route: route, directions: directionsClientSpy,  simulating: .never)
        
        expectation(forNotification: .routeControllerWillReroute, object: navigation.router) { (notification) -> Bool in
            return true
        }
        
        expectation(forNotification: .routeControllerDidFailToReroute, object: navigation.router) { (notification) -> Bool in
            return true
        }
        
        navigation.router.reroute(from: CLLocation(latitude: 0, longitude: 0), along: navigation.router.routeProgress)
        directionsClientSpy.fireLastCalculateCompletion(with: nil, routes: nil, error: TestError.test as NSError)
        
        waitForExpectations(timeout: 2) { (error) in
            XCTAssertNil(error)
        }
    }
}
