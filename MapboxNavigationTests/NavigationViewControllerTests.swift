import XCTest
import MapboxDirections
import MapboxCoreNavigation
import Turf
@testable import MapboxNavigation

var customRoadName = [CLLocationCoordinate2D: String?]()
let response = Fixture.JSONFromFileNamed(name: "route-with-instructions")

class NavigationViewControllerTests: XCTestCase {
    
    lazy var dependencies: (navigationViewController: NavigationViewController, startLocation: CLLocation, poi: [CLLocation], endLocation: CLLocation, dummyNavigationViewController: NavigationViewController) = {
        
        let navigationViewController = NavigationViewControllerSpy(for: initialRoute, directions: Directions(accessToken: "pk.feedCafeDeadBeefBadeBede"))
        let dummyNavigationViewController = NavigationViewControllerFakeSpy(for: initialRoute)
       
        let routeController = navigationViewController.routeController!
        let firstCoord      = routeController.routeProgress.currentLegProgress.nearbyCoordinates.first!
        let firstLocation   = location(at: firstCoord)
        
        var poi = [CLLocation]()
        let taylorStreetIntersection = routeController.routeProgress.route.legs.first!.steps.first!.intersections!.first!
        let turkStreetIntersection   = routeController.routeProgress.route.legs.first!.steps[3].intersections!.first!
        let fultonStreetIntersection = routeController.routeProgress.route.legs.first!.steps[5].intersections!.first!
        
        poi.append(location(at: taylorStreetIntersection.location))
        poi.append(location(at: turkStreetIntersection.location))
        poi.append(location(at: fultonStreetIntersection.location))
        
        let lastCoord    = routeController.routeProgress.currentLegProgress.remainingSteps.last!.coordinates!.first!
        let lastLocation = location(at: lastCoord)
        
        return (navigationViewController: navigationViewController, startLocation: firstLocation, poi: poi, endLocation: lastLocation, dummyNavigationViewController: dummyNavigationViewController)
    }()
    
    lazy var initialRoute: Route = {
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let route     = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], routeOptions: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
        
        route.accessToken = "nonsense"
        
        return route
    }()
    
    override func setUp() {
        super.setUp()
        customRoadName.removeAll()
    }
    
    func testNavigationViewControllerDelegateRoadNameAtLocation() {

        // The road name to display in the label, or the empty string to hide the label, or nil to query the map’s vector tiles for the road name.

        let navigationViewController = dependencies.navigationViewController
        var routeController = navigationViewController.routeController!
        
        // Identify a location to set the custom road name.
        let taylorStreetLocation = dependencies.poi.first!
        var roadName = "Taylor Swift Street"
        customRoadName[taylorStreetLocation.coordinate] = roadName
        
        // Test 1: navigationViewController(_:roadNameAt:) delegate method is implemented,
        //         with a road name provided and wayNameView label is visible.
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [taylorStreetLocation])
        
        var wayNameView = (navigationViewController.mapViewController?.navigationView.wayNameView)!
        var currentRoadName = wayNameView.text!
        XCTAssertEqual(currentRoadName, roadName, "Expected: \(roadName); Actual: \(currentRoadName)")
        XCTAssertFalse(wayNameView.isHidden, "WayNameView should been visible.")
    
        // Identify a location to set the custom road name.
        let turkStreetLocation = dependencies.poi[1]
        roadName = ""
        customRoadName[turkStreetLocation.coordinate] = roadName
        
        // Test 2: navigationViewController(_:roadNameAt:) delegate method is implemented,
        //         with a blank road name (empty string) provided and wayNameView label is hidden.
        
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [turkStreetLocation])
        wayNameView = (navigationViewController.mapViewController?.navigationView.wayNameView)!
        currentRoadName = wayNameView.text!
        XCTAssertEqual(currentRoadName, roadName, "Expected: \(roadName); Actual: \(currentRoadName)")
        XCTAssertTrue(wayNameView.isHidden, "WayNameView should been hidden.")
        
        // NavigationViewControllerDelegate.navigationViewController(_:roadNameAt:) is unimplemented: fall back to the tile-querying implementation.
        
        // Test 3: navigationViewController(_:roadNameAt:) delegate method is implemented,
        //         with a blank road name (empty string) provided and wayNameView label is hidden.
        let dummyNavigationViewController = dependencies.dummyNavigationViewController
        
        /**
         
         The style currently displayed in the receiver.
         Unlike the `styleURL` property, this property is set to an object that allows you to manipulate every aspect of the style locally.
         If the style is loading, this property is set to `nil` until the style finishes loading. If the style has failed to load, this property is set to `nil`. Because the style loads asynchronously, you should manipulate it in the `-[MGLMapViewDelegate mapView:didFinishLoadingStyle:]` or `-[MGLMapViewDelegate mapViewDidFinishLoadingMap:]` method. It is not possible to manipulate the style before it has finished loading.
         */
        
        
        // Identify a location without a custom road name.
        let fultonStreetLocation = dependencies.poi[2]
        routeController = dummyNavigationViewController.routeController
        
        let url = URL(string: "mapbox://styles/mapbox/streets-v9")
        let mapView = MGLMapView(frame: (dummyNavigationViewController.mapView?.bounds)!, styleURL: url)
        dummyNavigationViewController.mapView?.delegate?.mapView?(dummyNavigationViewController.mapView!, didFinishLoading: mapView.style!)
        dummyNavigationViewController.mapView?.delegate?.mapViewDidFinishLoadingMap?(dummyNavigationViewController.mapView!)
        routeController.locationManager(routeController.locationManager, didUpdateLocations: [fultonStreetLocation])
        currentRoadName = "Fulton Street"
        wayNameView = (dummyNavigationViewController.mapViewController?.navigationView.wayNameView)!
        currentRoadName = wayNameView.text!
        XCTAssertEqual(currentRoadName, roadName, "Expected: \(roadName); Actual: \(currentRoadName)")
        XCTAssertFalse(wayNameView.isHidden, "WayNameView should be visible.")
        
    }
}

class NavigationViewControllerSpy: NavigationViewController { }
class NavigationViewControllerFakeSpy: NavigationViewController { }

extension NavigationViewControllerSpy: NavigationViewControllerDelegate {
    
    override func mapViewController(_ mapViewController: RouteMapViewController, roadNameAt location: CLLocation) -> String? {
        return customRoadName[location.coordinate] ?? nil
    }
}

extension CLLocationCoordinate2D: Hashable {
    // Hash value property multiplied by a prime constant.
    public var hashValue: Int {
        return latitude.hashValue ^ longitude.hashValue &* 16777619
    }
    
    static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension NavigationViewControllerTests {
        fileprivate func location(at coordinate: CLLocationCoordinate2D) -> CLLocation {
                return CLLocation(coordinate: coordinate,
                                    altitude: 5,
                          horizontalAccuracy: 10,
                            verticalAccuracy: 5,
                                      course: 20,
                                       speed: 15,
                                   timestamp: Date())
            }
}
