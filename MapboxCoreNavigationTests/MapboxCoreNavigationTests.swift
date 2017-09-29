import XCTest
import MapboxDirections
import Turf
@testable import MapboxCoreNavigation

let response = Fixture.JSONFromFileNamed(name: "route")
let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String : Any]
let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
let directions = Directions(accessToken: "pk.feedCafeDeadBeefBadeBede")
let route = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], routeOptions: RouteOptions(waypoints: [waypoint1, waypoint2]))

let waitForInterval: TimeInterval = 5


class MapboxCoreNavigationTests: XCTestCase {
    
    func testDepart() {
        route.accessToken = "foo"
        let navigation = RouteController(along: route, directions: directions)
        navigation.resume()
        let depart = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 0, speed: 10, timestamp: Date())
        
        self.expectation(forNotification: RouteControllerAlertLevelDidChange.rawValue, object: navigation) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 2)
            
            let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as? RouteProgress
            let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
            
            return routeProgress != nil && routeProgress?.currentLegProgress.alertUserLevel == .depart && round(userDistance) == 384
        }
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [depart])
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testLowAlert() {
        route.accessToken = "foo"
        let locations = [CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.789118, longitude: -122.432209),
                                    altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 171, speed: 10, timestamp: Date())]
        let locationManager = ReplayLocationManager(locations: locations)
        let navigation = RouteController(along: route, directions: directions, locationManager: locationManager)
        
        self.expectation(forNotification: RouteControllerAlertLevelDidChange.rawValue, object: navigation) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 2)
            
            let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as? RouteProgress
            let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
            
            return routeProgress?.currentLegProgress.alertUserLevel == .low && routeProgress?.currentLegProgress.stepIndex == 2 && round(userDistance) == 1786
        }
        
        navigation.resume()
        navigation.routeProgress.currentLegProgress.stepIndex = 2
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testShouldReroute() {
        route.accessToken = "foo"
        let firstLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 38, longitude: -123),
                                       altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0,
                                       timestamp: Date())
        
        let secondLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 38, longitude: -124),
                                        altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0,
                                        timestamp: Date(timeIntervalSinceNow: 5))
        
        let locationManager = ReplayLocationManager(locations: [firstLocation, secondLocation])
        let navigation = RouteController(along: route, directions: directions, locationManager: locationManager)
        
        self.expectation(forNotification: RouteControllerWillReroute.rawValue, object: navigation) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let location = notification.userInfo![RouteControllerNotificationLocationKey] as? CLLocation
            return location?.coordinate == secondLocation.coordinate
        }
        
        navigation.resume()
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testArrive() {
        let bundle = Bundle(for: MapboxCoreNavigationTests.self)
        let filePath = bundle.path(forResource: "tunnel", ofType: "json")!
        
        let locations = Array<CLLocation>.locations(from: filePath)!
        let locationManager = ReplayLocationManager(locations: locations)
        locationManager.speedMultiplier = 20
        
        let routeFilePath = bundle.path(forResource: "tunnel", ofType: "route")!
        let route = NSKeyedUnarchiver.unarchiveObject(withFile: routeFilePath) as! Route
        route.accessToken = "foo"
        let navigation = RouteController(along: route, directions: directions, locationManager: locationManager)
        
        self.expectation(forNotification: RouteControllerProgressDidChange.rawValue, object: navigation) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as? RouteProgress
            guard let alertLevel = routeProgress?.currentLegProgress.alertUserLevel else {
                return false
            }
            
            return alertLevel == .arrive
        }
        
        navigation.resume()
        
        let timeout = locations.last!.timestamp.timeIntervalSince(locations.first!.timestamp) / locationManager.speedMultiplier
        waitForExpectations(timeout: timeout + 2) { (error) in
            XCTAssertNil(error)
        }
    }
}
