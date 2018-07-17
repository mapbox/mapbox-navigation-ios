import XCTest
import MapboxDirections
import Turf
@testable import MapboxCoreNavigation

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
let tunnelRoute = Route(json: tunnelJsonRoute, waypoints: [tunnelWayPoint1, tunnelWaypoint2], options: NavigationRouteOptions(waypoints: [tunnelWayPoint1, tunnelWaypoint2]))

class TunnelIntersectionManagerTests: XCTestCase {
    
    lazy var tunnelSetup: (tunnelIntersectionManager: TunnelIntersectionManager, routeController: RouteController, firstLocation: CLLocation) = {
        tunnelRoute.accessToken = "foo"
        let navigation = RouteController(along: tunnelRoute, directions: directions)
        let firstCoord = navigation.routeProgress.currentLegProgress.nearbyCoordinates.first!
        let tunnelIntersectionManager = TunnelIntersectionManager()
        
        return (tunnelIntersectionManager: tunnelIntersectionManager,
                          routeController: navigation,
                            firstLocation: CLLocation(coordinate: firstCoord,
                                                        altitude: 5,
                                              horizontalAccuracy: 10,
                                                verticalAccuracy: 5,
                                                          course: 20,
                                                           speed: 6,
                                timestamp: Date()))
    }()
    
    func testUserWithinTunnelEntranceRadius() {
        let routeController = tunnelSetup.routeController
        
        routeController.tunnelIntersectionManager = tunnelSetup.tunnelIntersectionManager
        
        let tunnelIntersectionManager = routeController.tunnelIntersectionManager
        
        // Set tunnel intersection manager's delegate
        tunnelIntersectionManager.delegate = routeController
        
        // Advance to step with a tunnel intersection
        routeController.advanceStepIndex(to: 1)
        
        // Intersection with a tunnel roadClass
        let tunnelIntersection = routeController.routeProgress.currentLegProgress.currentStep.intersections![1]
        let intersectionLocation = tunnelIntersection.location
        
        // Mock location moved from the first location on route to the tunnel intersection location
        var currentLocation = location(at: tunnelSetup.firstLocation.coordinate,
                                      for: routeController,
                             intersection: tunnelIntersection,
                                 distance: intersectionLocation.distance(to: tunnelSetup.firstLocation.coordinate))
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [currentLocation])
        
        // Set location to the entrance of the tunnel intersection
        let tunnelEntranceLocation = CLLocation(latitude: intersectionLocation.latitude, longitude: intersectionLocation.longitude)
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [tunnelEntranceLocation])
        
        var userIsAtTunnelEntranceRadius = tunnelIntersectionManager.userWithinTunnelEntranceRadius(at: currentLocation, routeProgress: routeController.routeProgress)
        XCTAssertTrue(userIsAtTunnelEntranceRadius, "Location must be within the tunnel entrance radius")
        
        let outsideTunnelEntranceRadius = intersectionLocation.coordinate(at: 200, facing: intersectionLocation.direction(to: tunnelSetup.firstLocation.coordinate))
        let outsideTunnelEntranceRadiusLocation = CLLocation(latitude: outsideTunnelEntranceRadius.latitude, longitude: outsideTunnelEntranceRadius.longitude)
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [outsideTunnelEntranceRadiusLocation])
        
        currentLocation = location(at: tunnelSetup.firstLocation.coordinate,
                                  for: routeController,
                         intersection: tunnelIntersection,
                             distance: 10)
        
        userIsAtTunnelEntranceRadius = tunnelIntersectionManager.userWithinTunnelEntranceRadius(at: currentLocation, routeProgress: routeController.routeProgress)
        XCTAssertFalse(userIsAtTunnelEntranceRadius, "Location must not be within the tunnel entrance radius")
    }
    
    func testTunnelDetected() {
        let routeController = tunnelSetup.routeController
        
        routeController.tunnelIntersectionManager = tunnelSetup.tunnelIntersectionManager
        routeController.tunnelIntersectionManager.delegate = routeController
        
        // Step with a tunnel intersection
        routeController.advanceStepIndex(to: 1)
        
        let tunnelIntersection = routeController.routeProgress.currentLegProgress.currentStep.intersections![1]
        var fakeLocation = location(at: tunnelSetup.firstLocation.coordinate, for: routeController, intersection: tunnelIntersection)
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [fakeLocation])
        
        let tunnelEntranceLocation = CLLocation(latitude: tunnelIntersection.location.latitude, longitude: tunnelIntersection.location.longitude)
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [tunnelEntranceLocation])
        
        var didDetectTunnel = routeController.tunnelIntersectionManager.userWithinTunnelEntranceRadius(at: routeController.location!, routeProgress: routeController.routeProgress)
        
        XCTAssertTrue(didDetectTunnel, "A tunnel should be detected at that location")
        
        // Step without a tunnel intersection
        routeController.advanceStepIndex(to: 2)
        
        fakeLocation = location(at: tunnelSetup.firstLocation.coordinate, for: routeController, intersection: routeController.routeProgress.currentLegProgress.currentStep.intersections![0])
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [fakeLocation])
        
        didDetectTunnel = routeController.tunnelIntersectionManager.userWithinTunnelEntranceRadius(at: routeController.location!, routeProgress: routeController.routeProgress)
        
        XCTAssertFalse(didDetectTunnel, "A tunnel should not exist at that location")
    }
    
    func testTunnelSimulatedNavigationEnabled() {
        let routeController = tunnelSetup.routeController
        
        routeController.tunnelIntersectionManager = tunnelSetup.tunnelIntersectionManager
        routeController.tunnelIntersectionManager.delegate = routeController
        
        // Step with a tunnel intersection
        routeController.advanceStepIndex(to: 1)
        
        // Intersection with a tunnel roadClass
        let tunnelIntersection = routeController.routeProgress.currentLegProgress.currentStep.intersections![1]
        let intersectionLocation = tunnelIntersection.location
        
        let currentLocation = location(at: tunnelSetup.firstLocation.coordinate,
                                      for: routeController,
                             intersection: tunnelIntersection,
                                 distance: intersectionLocation.distance(to: tunnelSetup.firstLocation.coordinate))
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [currentLocation])
        
        let upcomingIntersection = routeController.routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection!
        let tunnelLocation = location(at: upcomingIntersection.location, horizontalAccuracy: 20)
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [tunnelLocation])
        
        // Enable the tunnel animation, which should enable the simulated location manager
        routeController.tunnelIntersectionManager.delegate?.tunnelIntersectionManager?(routeController.tunnelIntersectionManager, willEnableAnimationAt: routeController.location!)
        XCTAssertTrue(routeController.tunnelIntersectionManager.isAnimationEnabled, "Animation through tunnel should be enabled.")
    }
    
    func testTunnelSimulatedNavigationDisabled() {
        let routeController = tunnelSetup.routeController
        
        routeController.tunnelIntersectionManager = tunnelSetup.tunnelIntersectionManager
        routeController.tunnelIntersectionManager.delegate = routeController
        
        // Step after a tunnel intersection
        routeController.advanceStepIndex(to: 2)
        
        // Intersection without a tunnel roadClass
        let tunnelExitIntersection = routeController.routeProgress.currentLegProgress.currentStep.intersections![0]
        let intersectionLocation = tunnelExitIntersection.location
        
        let currentLocation = location(at: tunnelSetup.firstLocation.coordinate,
                                      for: routeController,
                             intersection: tunnelExitIntersection,
                                 distance: intersectionLocation.distance(to: tunnelSetup.firstLocation.coordinate))
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [currentLocation])
        
        // Disable the tunnel animation, which should disable the simulated location manager
        // Assuming the tunnel animation was previously enabled
        routeController.tunnelIntersectionManager.isAnimationEnabled = true
        
        let tunnelExitLocation = location(at: routeController.location!.coordinate, horizontalAccuracy: 20)

        XCTAssertEqual(routeController.tunnelIntersectionManager.delegate as? NSObject, routeController)
        routeController.tunnelIntersectionManager(routeController.tunnelIntersectionManager, willDisableAnimationAt: tunnelExitLocation)
        XCTAssertNotNil(routeController.tunnelIntersectionManager)
        let tunnelIntersectionManager = routeController.tunnelIntersectionManager
        XCTAssertTrue(tunnelIntersectionManager.isAnimationEnabled, "Animation through tunnel should remain enabled after 1 location update.")
        routeController.tunnelIntersectionManager(routeController.tunnelIntersectionManager, willDisableAnimationAt: tunnelExitLocation)
        XCTAssertTrue(tunnelIntersectionManager.isAnimationEnabled, "Animation through tunnel should remain enabled after 2 location updates.")
        routeController.tunnelIntersectionManager(routeController.tunnelIntersectionManager, willDisableAnimationAt: tunnelExitLocation)
        XCTAssertFalse(tunnelIntersectionManager.isAnimationEnabled, "Animation through tunnel should be disabled after 3 location updates.")
    }
    
}

extension TunnelIntersectionManagerTests {
    
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
    
    fileprivate func location(at coordinate: CLLocationCoordinate2D, horizontalAccuracy: CLLocationAccuracy? = 258.20) -> CLLocation {
        return CLLocation(coordinate: coordinate,
                            altitude: 5,
                  horizontalAccuracy: horizontalAccuracy!,
                    verticalAccuracy: 200,
                              course: 20,
                               speed: 15,
                           timestamp: Date())
    }
}
