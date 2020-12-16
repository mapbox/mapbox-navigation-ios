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

    // MARK: - Route congestion consistency tests
    
    func loadRoute(from jsonFile: String) -> Route {
        let defaultRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2DMake(16.983119, 51.045222),
            CLLocationCoordinate2DMake(16.99842, 51.034759)
        ])
        
        let routeData = Fixture.JSONFromFileNamed(name: jsonFile)
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = defaultRouteOptions
        
        var route: Route? = nil
        XCTAssertNoThrow(route = try decoder.decode(Route.self, from: routeData))
        
        guard let validRoute = route else {
            preconditionFailure("Route is invalid.")
        }
        
        return validRoute
    }
    
    func congestionLevel(_ feature: MGLPolylineFeature) -> CongestionLevel? {
        guard let congestionLevel = feature.attributes["congestion"] as? String else { return nil }
        
        return CongestionLevel(rawValue: congestionLevel)
    }
    
    func testOverriddenStreetsRouteClassTunnelSingleCongestionLevel() {
        let route = loadRoute(from: "route-with-road-classes-single-congestion")
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        var congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        XCTAssertEqual(congestions?.count, 1)
        
        // Since `NavigationMapView.addCongestion(to:legIndex:)` merges congestion levels which are similar
        // it is expected that only one congestion level is shown for this route.
        var expectedCongestionLevel: CongestionLevel = .unknown
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevel)
        }
        
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.golf]
        expectedCongestionLevel = .low
        congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevel)
        }
    }
    
    func testOverriddenStreetsRouteClassMotorwayMixedCongestionLevels() {
        let route = loadRoute(from: "route-with-mixed-road-classes")
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        var congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        XCTAssertEqual(congestions?.count, 5)
        
        var expectedCongestionLevels: [CongestionLevel] = [
            .unknown,
            .severe,
            .unknown,
            .severe,
            .unknown
        ]
        
        // Since `NavigationMapView.addCongestion(to:legIndex:)` merges congestion levels which are similar
        // in such case it is expected that mixed congestion levels remain unmodified.
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.motorway]
        expectedCongestionLevels = [
            .low,
            .severe,
            .low,
            .severe,
            .low
        ]
        congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
    }
    
    func testOverriddenStreetsRouteClassMissing() {
        let route = loadRoute(from: "route-with-missing-road-classes")
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.motorway]
        
        var congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        XCTAssertEqual(congestions?.count, 3)
        
        var expectedCongestionLevels: [CongestionLevel] = [
            .severe,
            .low,
            .severe
        ]
        
        // In case if `roadClassesWithOverriddenCongestionLevels` was provided with `.motorway` `MapboxStreetsRoadClass` it is expected
        // that any `.unknown` congestion level for such `MapboxStreetsRoadClass` will be overwritten to `.low` congestion level.
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        navigationMapView.roadClassesWithOverriddenCongestionLevels = []
        expectedCongestionLevels[1] = .unknown
        congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        
        // In case if `roadClassesWithOverriddenCongestionLevels` is empty `.unknown` congestion level will not be
        // overwritten.
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        // Make sure that at certain indexes `MapboxStreetsRoadClass` is not present and assigned to `nil`.
        route.legs.forEach {
            let streetsRoadClasses = $0.streetsRoadClasses
            
            for index in 24...27 {
                XCTAssertEqual(streetsRoadClasses[index], nil)
            }
        }
    }
    
    func testRouteStreetsRoadClassesCountEqualToCongestionLevelsCount() {
        let route = loadRoute(from: "route-with-missing-road-classes")
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.motorway]
        
        // Make sure that number of `MapboxStreetsRoadClass` is equal to number of congestion levels.
        route.legs.forEach {
            let streetsRoadClasses = $0.streetsRoadClasses
            let segmentCongestionLevels = $0.segmentCongestionLevels
            
            XCTAssertEqual(streetsRoadClasses.count, segmentCongestionLevels?.count)
        }
    }
    
    func testRouteStreetsRoadClassesNotPresent() {
        let route = loadRoute(from: "route-with-not-present-road-classes")
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        var congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        let expectedCongestionLevels: [CongestionLevel] = [
            .unknown,
            .low,
            .moderate,
            .unknown,
            .low
        ]
        
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.motorway, .secondary, .ferry]
        congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        
        // Since `SreetsRoadClass`es are not present in this route congestion levels should remain unchanged after
        // modifying `roadClassesWithOverriddenCongestionLevels`, `streetsRoadClasses` should be empty as well.
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        route.legs.forEach {
            let streetsRoadClasses = $0.streetsRoadClasses

            XCTAssertEqual(streetsRoadClasses.count, 0)
        }
    }
    
    func testRouteStreetsRoadClassesDifferentAndSameCongestion() {
        let route = loadRoute(from: "route-with-same-congestion-different-road-classes")
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        var congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        var expectedCongestionLevels: [CongestionLevel] = [
            .unknown
        ]
        
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        // It is expected that congestion will be overridden only for `RoadClasses` added in `roadClassesWithOverriddenCongestionLevels`.
        // Other congestions should remain unchanged.
        expectedCongestionLevels = [
            .low,
            .unknown
        ]
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.street]
        congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.street, .ferry]
        congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        // Since there is only one type of congestion and three `RoadClasses` after overriding all of them
        // all congestion levels should we changed from `.unknown` to `.low`.
        expectedCongestionLevels = [
            .low
        ]
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.street, .ferry, .motorway]
        congestions = navigationMapView.addCongestion(to: route, legIndex: 0)
        
        congestions?.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
    }
    
    func testRoadClassesWithOverriddenCongestionLevelsRemovesDuplicates() {
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus), styleURL: Fixture.blankStyle)
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.aerialway, .construction, .construction, .golf]
        
        XCTAssertEqual(navigationMapView.roadClassesWithOverriddenCongestionLevels?.count, 3)
    }
}

class PersistentAnnotation: MGLPointAnnotation { }

