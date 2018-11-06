import XCTest
import MapboxDirections
import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation


class NavigationMapViewTests: XCTestCase, MGLMapViewDelegate {
    
    let response = Fixture.JSONFromFileNamed(name: "route-with-instructions")
    var styleLoadingExpectation: XCTestExpectation?
    var mapView: NavigationMapView?
    
    lazy var route: Route = {
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let route     = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], options: NavigationRouteOptions(waypoints: [waypoint1, waypoint2]))
        route.accessToken = "foo"
        return route
    }()
    
    override func setUp() {
        super.setUp()
        
        mapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        mapView!.delegate = self
        if mapView!.style == nil {
            styleLoadingExpectation = expectation(description: "Style Loaded Expectation")
            waitForExpectations(timeout: 2, handler: nil)
        }
    }
    
    override func tearDown() {
        styleLoadingExpectation = nil
        mapView = nil
        super.tearDown()
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        XCTAssertNotNil(mapView.style)
        XCTAssertEqual(mapView.style, style)
        styleLoadingExpectation!.fulfill()
    }
    
    let coordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1),
        CLLocationCoordinate2D(latitude: 2, longitude: 2),
        CLLocationCoordinate2D(latitude: 3, longitude: 3),
        CLLocationCoordinate2D(latitude: 4, longitude: 4),
        CLLocationCoordinate2D(latitude: 5, longitude: 5),
        ]
    
    func testNavigationMapViewCombineWithSimilarCongestions() {
        let congestionSegments = mapView!.combine(coordinates, with: [
            .low,
            .low,
            .low,
            .low,
            .low
            ])
        
        XCTAssertEqual(congestionSegments.count, 1)
        XCTAssertEqual(congestionSegments[0].0.count, 10)
        XCTAssertEqual(congestionSegments[0].1, .low)
    }
    
    func testNavigationMapViewCombineWithDissimilarCongestions() {
        
        let congestionSegmentsSevere = mapView!.combine(coordinates, with: [
            .low,
            .low,
            .severe,
            .low,
            .low
            ])
        
        // The severe breaks the trend of .low.
        // Any time the current congestion level is different than the previous segment, we have to create a new congestion segment.
        XCTAssertEqual(congestionSegmentsSevere.count, 3)
        
        XCTAssertEqual(congestionSegmentsSevere[0].0.count, 4)
        XCTAssertEqual(congestionSegmentsSevere[1].0.count, 2)
        XCTAssertEqual(congestionSegmentsSevere[2].0.count, 4)
        
        XCTAssertEqual(congestionSegmentsSevere[0].1, .low)
        XCTAssertEqual(congestionSegmentsSevere[1].1, .severe)
        XCTAssertEqual(congestionSegmentsSevere[2].1, .low)
    }
    
    func testRemoveWaypointsDoesNotRemoveUserAnnotations() {
        XCTAssertNil(mapView!.annotations)
        mapView!.addAnnotation(MGLPointAnnotation())
        mapView!.addAnnotation(PersistentAnnotation())
        XCTAssertEqual(mapView!.annotations!.count, 2)
        
        mapView!.showWaypoints(route)
        XCTAssertEqual(mapView!.annotations!.count, 3)
        
        mapView!.removeWaypoints()
        XCTAssertEqual(mapView!.annotations!.count, 2)
        
        // Clean up
        mapView!.removeAnnotations(mapView!.annotations ?? [])
        XCTAssertNil(mapView!.annotations)
    }
}

class PersistentAnnotation: MGLPointAnnotation { }

