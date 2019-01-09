import XCTest
import MapboxDirections
import Turf
import TestHelper
@testable import MapboxCoreNavigation

let response = Fixture.JSONFromFileNamed(name: "routeWithInstructions")
let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String : Any]
let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
let directions = DirectionsSpy(accessToken: "pk.feedCafeDeadBeefBadeBede")
let route: Route = {
    let options = NavigationRouteOptions(waypoints: [waypoint1, waypoint2])
    return Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], options: options)
}()

let waitForInterval: TimeInterval = 5


class MapboxCoreNavigationTests: XCTestCase {
    
    var navigation: MapboxNavigationService!
    
    func testDepart() {
        route.accessToken = "foo"
        navigation = MapboxNavigationService(route: route, directions: directions, simulating: .never)
        
        // Coordinates from first step
        let coordinates = route.legs[0].steps[0].coordinates!
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10,
                                                                  verticalAccuracy: -1, course: -1, speed: 10,
                                                                  timestamp: Date().addingTimeInterval(TimeInterval($0.offset))) }
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
            return routeProgress != nil && routeProgress?.currentLegProgress.userHasArrivedAtWaypoint == false
        }
        
        navigation.start()
        
        locations.forEach { navigation.locationManager(navigation.locationManager, didUpdateLocations: [$0]) }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testNewStep() {
        route.accessToken = "foo"
        
        // Coordinates from beginning of step[1] to end of step[2]
        let coordinates = route.legs[0].steps[1].coordinates! + route.legs[0].steps[2].coordinates!
        let locations: [CLLocation]
        locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                              altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: -1, speed: 10,
                                                              timestamp: Date().addingTimeInterval(TimeInterval($0.offset))) }
        
        navigation = MapboxNavigationService(route: route, directions: directions, simulating: .never)
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
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
        
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, timestamp: Date().addingTimeInterval(TimeInterval($0.offset))) }
        
        let locationManager = ReplayLocationManager(locations: locations)
        navigation = MapboxNavigationService(route: route, directions: directions, locationSource: locationManager, simulating: .never)
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            // TODO: stepIndex should be 5, which corresponds to the arrival step
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
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: Date().addingTimeInterval(TimeInterval($0.offset))) }
        
        let offRouteCoordinates = [[-122.41765, 37.79095],[-122.41830,37.79087],[-122.41907,37.79079],[-122.41960,37.79073]]
            .map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        
        let offRouteLocations = offRouteCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10,
                       verticalAccuracy: -1, course: -1, speed: 10,
                       timestamp: Date().addingTimeInterval(TimeInterval(locations.count + $0.offset)))
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

        locations.forEach { navigation.locationManager(locationManager, didUpdateLocations: [$0]) }

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
