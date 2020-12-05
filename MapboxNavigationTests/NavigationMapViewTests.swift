import XCTest
import MapboxDirections
import TestHelper
import Turf
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class NavigationMapViewTests: XCTestCase, MGLMapViewDelegate {
    let response = Fixture.routeResponse(from: "route-with-instructions", options: NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
        CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
    ]))
    var styleLoadingExpectation: XCTestExpectation?
    var mapView: NavigationMapView?
    
    lazy var route: Route = {
        let route = response.routes!.first!
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
        
        mapView!.showWaypoints(on: route)
        XCTAssertEqual(mapView!.annotations!.count, 3)
        
        mapView!.removeWaypoints()
        XCTAssertEqual(mapView!.annotations!.count, 2)
        
        // Clean up
        mapView!.removeAnnotations(mapView!.annotations ?? [])
        XCTAssertNil(mapView!.annotations)
    }
    
    func setUpVanishingRouteLine() -> Route {
        let routeData = Fixture.JSONFromFileNamed(name: "route-for-vanishing-route-line")
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2DMake(-122.5237734,37.9753973),
            CLLocationCoordinate2DMake(-122.5264995,37.9709171)
        ])
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        var testRoute: Route?
        XCTAssertNoThrow(testRoute = try decoder.decode(Route.self, from: routeData))
        guard let route = testRoute else {
            preconditionFailure("Route is invalid.")
        }
        return route
    }
    
    func testUpdateVanishingPoint() {
        let route = setUpVanishingRouteLine()
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        let shape = route.shape!
        let targetPoint = Turf.mid(shape.coordinates[6], shape.coordinates[7])
        //which is between route.legs[0].steps[1].shape!.coordinates[3] and  route.legs[0].steps[1].shape!.coordinates[4]
        let traveledCoordinates = Array(route.legs[0].steps[1].shape!.coordinates[0...3])
        let stepTraveledDistancePrep = navigationMapView.calculateGranularDistances(traveledCoordinates)?.distance
        guard let stepTraveledDistanceSep = stepTraveledDistancePrep else {
            preconditionFailure("Granular distances are invalid")
        }

        let testRouteProgress: RouteProgress = RouteProgress(route: route, routeIndex: 0, options: routeOptions, legIndex: 0, spokenInstructionIndex: 0)
        testRouteProgress.currentLegProgress = RouteLegProgress(leg: route.legs[0], stepIndex: 1, spokenInstructionIndex: 0)
        testRouteProgress.currentLegProgress.currentStepProgress = RouteStepProgress(step: route.legs[0].steps[1], spokenInstructionIndex: 0)
        testRouteProgress.currentLegProgress.currentStepProgress.distanceTraveled = stepTraveledDistanceSep

        navigationMapView.initPrimaryRoutePoints(route: route)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: testRouteProgress)
        navigationMapView.updateTraveledRouteLine(targetPoint)

        let expectedTraveledFraction = 0.06383308537010246
        XCTAssertEqual(navigationMapView.fractionTraveled, expectedTraveledFraction)
    }
    
    func testParseRoutePoints() {
        let route = setUpVanishingRouteLine()
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        
        navigationMapView.initPrimaryRoutePoints(route: route)
        let nestedList = navigationMapView.routePoints?.nestedList
        let flatList = navigationMapView.routePoints?.flatList
        let distanceArray = navigationMapView.routeLineGranularDistances?.distanceArray
        XCTAssertEqual(nestedList?.first?.count, 8)
        XCTAssertEqual(flatList?.count, 33)
        XCTAssertEqual(distanceArray?.count, 33)
        XCTAssertEqual(distanceArray?[32].distanceRemaining, 0)
    }

}

class PersistentAnnotation: MGLPointAnnotation { }

