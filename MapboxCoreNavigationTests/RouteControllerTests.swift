import XCTest
import MapboxDirections
import Turf
@testable import MapboxCoreNavigation

fileprivate let mbTestHeading: CLLocationDirection = 50

struct TunnelDetectorTestData {
    static let ninthStreetFileName = "routeWithTunnels_9thStreetDC"
    static let kRouteKey = "routes"
    static let startLocation = CLLocationCoordinate2D(latitude: 38.890774, longitude: -77.023970)
    static let endLocation = CLLocationCoordinate2D(latitude: 38.88061238536352, longitude: -77.02471810711819)
}

let tunnelResponse = Fixture.JSONFromFileNamed(name: TunnelDetectorTestData.ninthStreetFileName)
let tunnelJsonRoute = (tunnelResponse[TunnelDetectorTestData.kRouteKey] as! [AnyObject]).first as! [String: Any]
let tunnelWayPoint1 = Waypoint(coordinate: TunnelDetectorTestData.startLocation)
let tunnelWaypoint2 = Waypoint(coordinate: TunnelDetectorTestData.endLocation)
let tunnelRoute = Route(json: tunnelJsonRoute, waypoints: [tunnelWayPoint1, tunnelWaypoint2], routeOptions: NavigationRouteOptions(waypoints: [tunnelWayPoint1, tunnelWaypoint2]))


class RouteControllerTests: XCTestCase {

    lazy var setup: (routeController: RouteController, firstLocation: CLLocation) = {
        route.accessToken = "foo"
        let navigation = RouteController(along: route, directions: directions)
        let firstCoord = navigation.routeProgress.currentLegProgress.nearbyCoordinates.first!
        return (routeController: navigation, firstLocation: CLLocation(coordinate: firstCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 4, timestamp: Date()))
    }()
    
    lazy var tunnelSetup: (routeController: RouteController, firstLocation: CLLocation) = {
       tunnelRoute.accessToken = "foo"
        let navigation = RouteController(along: tunnelRoute, directions: directions)
        let firstCoord = navigation.routeProgress.currentLegProgress.nearbyCoordinates.first!
        return (routeController: navigation, firstLocation: CLLocation(coordinate: firstCoord, altitude: 5, horizontalAccuracy: 10, verticalAccuracy: 5, course: 20, speed: 6, timestamp: Date()))
    }()
    
    func testUserIsOnRoute() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertTrue(navigation.userIsOnRoute(firstLocation), "User should be on route")
    }
    
    func testUserIsOffRoute() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        
        let coordinateOffRoute = firstLocation.coordinate.coordinate(at: 100, facing: 90)
        let locationOffRoute = CLLocation(latitude: coordinateOffRoute.latitude, longitude: coordinateOffRoute.longitude)
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [locationOffRoute])
        XCTAssertFalse(navigation.userIsOnRoute(locationOffRoute), "User should be off route")
    }
    
    func testAdvancingToFutureStepAndNotRerouting() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
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
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
    }
    
    func testSnappedLocationForUnqualifiedLocation() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
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
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String : Any]
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
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        
        XCTAssertEqual(navigation.location!.course, firstLocation.course, "Course should be using course")
        
        let invalidCourseLocation = CLLocation(coordinate: firstLocation.coordinate, altitude: firstLocation.altitude, horizontalAccuracy: firstLocation.horizontalAccuracy, verticalAccuracy: firstLocation.verticalAccuracy, course: -1, speed: firstLocation.speed, timestamp: firstLocation.timestamp)
        
        let heading = CLHeading(heading: mbTestHeading, accuracy: 1)!
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [invalidCourseLocation])
        navigation.locationManager(navigation.locationManager, didUpdateHeading: heading)
        
        XCTAssertEqual(navigation.location!.course, mbTestHeading, "Course should be using bearing")
    }

    func testUserWithinTunnelEntranceRadius() {
        let navigation = tunnelSetup.routeController
        
        // Step with a tunnel intersection
        navigation.advanceStepIndex(to: 1)
        
        // Intersection with a tunnel roadClass
        let tunnelIntersection = navigation.routeProgress.currentLegProgress.currentStep.intersections![1]
        let intersectionLocation = tunnelIntersection.location
        
        var currentLocation = location(at: tunnelSetup.firstLocation.coordinate,
                                       for: navigation,
                              intersection: tunnelIntersection,
                                  distance: intersectionLocation.distance(to: tunnelSetup.firstLocation.coordinate))

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [currentLocation])
        
        let tunnelEntranceLocation = CLLocation(latitude: intersectionLocation.latitude, longitude: intersectionLocation.longitude)
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [tunnelEntranceLocation])
        
        var userIsAtTunnelEntranceRadius = navigation.userWithinTunnelEntranceRadius(at: currentLocation, intersection: tunnelIntersection)
        XCTAssertTrue(userIsAtTunnelEntranceRadius, "Location must be within the tunnel entrance radius")

        let outsideTunnelEntranceRadius = intersectionLocation.coordinate(at: 200, facing: intersectionLocation.direction(to: tunnelSetup.firstLocation.coordinate))
        let outsideTunnelEntranceRadiusLocation = CLLocation(latitude: outsideTunnelEntranceRadius.latitude, longitude: outsideTunnelEntranceRadius.longitude)

        navigation.locationManager(navigation.locationManager, didUpdateLocations: [outsideTunnelEntranceRadiusLocation])
        
        currentLocation = location(at: tunnelSetup.firstLocation.coordinate,
                                   for: navigation,
                                   intersection: tunnelIntersection,
                                   distance: 10)
        userIsAtTunnelEntranceRadius = navigation.userWithinTunnelEntranceRadius(at: currentLocation, intersection: tunnelIntersection)
        XCTAssertFalse(userIsAtTunnelEntranceRadius, "Location must not outside the tunnel entrance radius")
    }
    
    // TODO: Check for Disabled Simulation
    func testTunnelSimulatedNavigation() {
        let navigation = tunnelSetup.routeController
        
        // Step with a tunnel intersection
        navigation.advanceStepIndex(to: 1)
        
        // Intersection with a tunnel roadClass
        let tunnelIntersection = navigation.routeProgress.currentLegProgress.currentStep.intersections![1]
        let intersectionLocation = tunnelIntersection.location
        
        let currentLocation = location(at: tunnelSetup.firstLocation.coordinate,
                                      for: navigation,
                             intersection: tunnelIntersection,
                                 distance: intersectionLocation.distance(to: tunnelSetup.firstLocation.coordinate))
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [currentLocation])
        
        let upcomingIntersection = navigation.routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection!
        let tunnelLocation = location(at: upcomingIntersection.location)
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [tunnelLocation])
        
        // Enable the tunnel animation, which should enable the simulated location manager
        let enableTunnelAnimationExpectation = expectation(description: "enableTunnelAnimation")

        navigation.enableTunnelAnimation(for: navigation.locationManager,
                               routeProgress: navigation.routeProgress,
                            distanceTraveled: navigation.routeProgress.currentLegProgress.currentStepProgress.distanceTraveled) { manager in
            
            enableTunnelAnimationExpectation.fulfill()
            
                                if manager is SimulatedLocationManager {
                                    print(" KOBE!!! KOBE!!! KOBE!!! \(manager is SimulatedLocationManager)")
                                }

            XCTAssertTrue(manager is SimulatedLocationManager,
                          "Location manager must be of type `SimulatedLocationManager` in order to simulate navigation.")
                        
        }
        
        self.wait(for: [enableTunnelAnimationExpectation], timeout: 1.0)
        
    }
    
    func testEnableTunnelAnimation() {
        let navigation = tunnelSetup.routeController
        
        // Step with a tunnel intersection
        navigation.advanceStepIndex(to: 1)
        
        let tunnelIntersection = navigation.routeProgress.currentLegProgress.currentStep.intersections![1]
        let fakeLocation = location(at: tunnelSetup.firstLocation.coordinate, for: navigation, intersection: tunnelIntersection)
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [fakeLocation])
        
        let tunnelEntranceLocation = CLLocation(latitude: tunnelIntersection.location.latitude, longitude: tunnelIntersection.location.longitude)
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [tunnelEntranceLocation])
        
        // test should animate tunnel navigation
        let currentIntersection = navigation.routeProgress.currentLegProgress.currentStepProgress.currentIntersection
        let currentLocation = location(at: navigation.location!.coordinate)
        XCTAssertTrue(navigation.shouldEnableTunnelAnimation(at: currentLocation, for: navigation.locationManager, intersection: currentIntersection), "Cannot animate tunnel navigation at that location")
    }

}

extension RouteControllerTests {
    
    fileprivate func location(at coordinate: CLLocationCoordinate2D,
                        for routeController: RouteController,
                               intersection: Intersection,
                                   distance: CLLocationDistance? = 200) -> CLLocation {
        
        let polyline = Polyline(routeController.routeProgress.currentLegProgress.currentStep.coordinates!)
        let newLocation = CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                longitude: coordinate.longitude).coordinate(
                                                       at: distance!,
                                                   facing: (polyline.coordinates.first?.direction(to: intersection.location))!
                                                )
        return location(at: newLocation)
    }
    
    fileprivate func location(at coordinate: CLLocationCoordinate2D) -> CLLocation {
        return CLLocation(coordinate: coordinate,
                          altitude: 5,
                          horizontalAccuracy: 258.20,
                          verticalAccuracy: 200,
                          course: 20,
                          speed: 15,
                          timestamp: Date())
    }
}
