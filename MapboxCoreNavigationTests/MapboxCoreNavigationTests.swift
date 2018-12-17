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
    options.shapeFormat = .polyline // NavigationRouteOptions defaults to `polyline6` but our fixtures are encoded using polyline5
    return Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], options: options)
}()

let waitForInterval: TimeInterval = 5


class MapboxCoreNavigationTests: XCTestCase {
    
    var navigation: MapboxNavigationService!
    
    func testDepart() {
        route.accessToken = "foo"
        navigation = MapboxNavigationService(route: route, directions: directions, simulating: .never)
        let depart = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 0, speed: 10, timestamp: Date())
        
        let locations = [depart.shifted(to: Date().addingTimeInterval(-5)),
                         depart.shifted(to: Date().addingTimeInterval(-4)),
                         depart.shifted(to: Date().addingTimeInterval(-3)),
                         depart.shifted(to: Date().addingTimeInterval(-2))]
        
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
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.78895, longitude: -122.42543), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 171, speed: 10, timestamp: Date())
        let echos = futureEcho(location: location)
        let locationManager = ReplayLocationManager(locations: echos)
        navigation = MapboxNavigationService(route: route, directions: directions, locationSource: locationManager, simulating: .never)
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
            return routeProgress?.currentLegProgress.stepIndex == 2
        }
        
        navigation.start()
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testJumpAheadToLastStep() {
        route.accessToken = "foo"
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.77386, longitude: -122.43085), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 171, speed: 10, timestamp: Date())
        
        let echos = futureEcho(location: location)
        let locationManager = ReplayLocationManager(locations: echos)
        navigation = MapboxNavigationService(route: route, directions: directions, locationSource: locationManager, simulating: .never)

        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
            return routeProgress?.currentLegProgress.stepIndex == 6
        }
        
        navigation.start()
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testShouldReroute() {
        route.accessToken = "foo"
        let firstLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165),
                                       altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0,
                                       timestamp: Date())
        
        let secondLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 38, longitude: -124),
                                        altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0,
                                        timestamp: Date(timeIntervalSinceNow: 5))
        let echos = futureEcho(location: firstLocation)
        let locations = echos + [secondLocation]
        let locationManager = ReplayLocationManager(locations: locations)
        navigation = MapboxNavigationService(route: route, directions: directions, locationSource: locationManager, simulating: .never)
        expectation(forNotification: .routeControllerWillReroute, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as? CLLocation
            return location?.coordinate == secondLocation.coordinate
        }
        
        navigation.start()
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testArrive() {
        route.accessToken = "foo"
        let locations: [CLLocation] = route.legs.first!.steps.first!.coordinates!.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        let locationManager = ReplayLocationManager(locations: locations)
        locationManager.speedMultiplier = 20
        
        navigation = MapboxNavigationService(route: route, directions: directions, locationSource: locationManager, simulating: .never)

        expectation(forNotification: .routeControllerProgressDidChange, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress
            return routeProgress != nil
        }
        
        navigation.start()
        
        let timeout = locations.last!.timestamp.timeIntervalSince(locations.first!.timestamp) / locationManager.speedMultiplier
        waitForExpectations(timeout: timeout + 2) { (error) in
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


fileprivate func futureEcho(location: CLLocation, times: Int = 4) -> [CLLocation] {
    let loop = 0...times
    let intervals = loop.map(TimeInterval.init(_:))
    let locations = intervals.map { shift(location: location, by: $0) }
    return locations
}

fileprivate func shift(location: CLLocation, by interval: TimeInterval) -> CLLocation {
    
    let newTime = location.timestamp.addingTimeInterval(interval)
    return CLLocation(coordinate: location.coordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: newTime)
}
