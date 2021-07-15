import XCTest
import MapboxDirections
import TestHelper
import Turf
import MapboxMaps
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class NavigationMapViewTests: TestCase {
    let response = Fixture.routeResponse(from: "route-with-instructions", options: NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
        CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
    ]))
    var navigationMapView: NavigationMapView!
    
    lazy var route: Route = {
        let route = response.routes!.first!
        return route
    }()
    
    override func setUp() {
        super.setUp()
        navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
    }
    
    override func tearDown() {
        navigationMapView = nil
        super.tearDown()
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
        let congestionSegments = coordinates.combined([
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
        let congestionSegmentsSevere = coordinates.combined([
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
        navigationMapView.pointAnnotationManager = navigationMapView.mapView.annotations.makePointAnnotationManager()
        let pointAnnotationManager = navigationMapView.pointAnnotationManager
        XCTAssertEqual(0, pointAnnotationManager?.annotations.count)
        pointAnnotationManager?.syncAnnotations([PointAnnotation(coordinate: CLLocationCoordinate2D()),
                                                 PointAnnotation(coordinate: CLLocationCoordinate2D())])
        XCTAssertEqual(pointAnnotationManager?.annotations.count, 2)
        
        navigationMapView.showWaypoints(on: route)
        XCTAssertEqual(pointAnnotationManager?.annotations.count, 1)
        
        navigationMapView.removeWaypoints()
        XCTAssertEqual(pointAnnotationManager?.annotations.count, 0)
        
        // Clean up
        pointAnnotationManager?.syncAnnotations([])
        XCTAssertEqual(0, pointAnnotationManager?.annotations.count)
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
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        let shape = route.shape!
        let targetPoint = Turf.mid(shape.coordinates[6], shape.coordinates[7])
        //which is between route.legs[0].steps[1].shape!.coordinates[3] and  route.legs[0].steps[1].shape!.coordinates[4]
        let traveledCoordinates = Array(route.legs[0].steps[1].shape!.coordinates[0...3])
        let stepTraveledDistancePrep = navigationMapView.calculateGranularDistances(traveledCoordinates)?.distance
        guard let stepTraveledDistanceSep = stepTraveledDistancePrep else {
            preconditionFailure("Granular distances are invalid")
        }

        let testRouteProgress: RouteProgress = RouteProgress(route: route, options: routeOptions, legIndex: 0, spokenInstructionIndex: 0)
        testRouteProgress.currentLegProgress = RouteLegProgress(leg: route.legs[0], stepIndex: 1, spokenInstructionIndex: 0)
        testRouteProgress.currentLegProgress.currentStepProgress = RouteStepProgress(step: route.legs[0].steps[1], spokenInstructionIndex: 0)
        testRouteProgress.currentLegProgress.currentStepProgress.distanceTraveled = stepTraveledDistanceSep

        navigationMapView.initPrimaryRoutePoints(route: route)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: testRouteProgress)
        navigationMapView.updateTraveledRouteLine(targetPoint)

        let expectedTraveledFraction = 0.06383308537010246

        XCTAssertTrue(abs(navigationMapView.fractionTraveled - expectedTraveledFraction) < 0.000000000001)
    }
    
    func testParseRoutePoints() {
        let route = setUpVanishingRouteLine()
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        
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
    
    func congestionLevel(_ feature: Turf.Feature) -> CongestionLevel? {
        guard let congestionLevel = feature.properties?["congestion"] as? String else { return nil }
        
        return CongestionLevel(rawValue: congestionLevel)
    }
    
    func testOverriddenStreetsRouteClassTunnelSingleCongestionLevel() {
        let route = loadRoute(from: "route-with-road-classes-single-congestion")
        var congestions = route.congestionFeatures()
        XCTAssertEqual(congestions.count, 1)
        
        // Since `Route.congestionFeatures(legIndex:isAlternativeRoute:roadClassesWithOverriddenCongestionLevels:)`
        // merges congestion levels which are similar it is expected that only one congestion
        // level is shown for this route.
        var expectedCongestionLevel: CongestionLevel = .unknown
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevel)
        }
        
        expectedCongestionLevel = .low
        congestions = route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: [.golf])
        
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevel)
        }
    }
    
    func testOverriddenStreetsRouteClassMotorwayMixedCongestionLevels() {
        let route = loadRoute(from: "route-with-mixed-road-classes")
        var congestions = route.congestionFeatures()
        XCTAssertEqual(congestions.count, 5)
        
        var expectedCongestionLevels: [CongestionLevel] = [
            .unknown,
            .severe,
            .unknown,
            .severe,
            .unknown
        ]
        
        // Since `Route.congestionFeatures(legIndex:isAlternativeRoute:roadClassesWithOverriddenCongestionLevels:)`
        // merges congestion levels which are similar in such case it is expected that mixed congestion
        // levels remain unmodified.
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        expectedCongestionLevels = [
            .low,
            .severe,
            .low,
            .severe,
            .low
        ]
        congestions = route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: [.motorway])
        
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
    }
    
    func testOverriddenStreetsRouteClassMissing() {
        let route = loadRoute(from: "route-with-missing-road-classes")
        
        var congestions = route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: [.motorway])
        XCTAssertEqual(congestions.count, 3)
        
        var expectedCongestionLevels: [CongestionLevel] = [
            .severe,
            .low,
            .severe
        ]
        
        // In case if `roadClassesWithOverriddenCongestionLevels` was provided with `.motorway` `MapboxStreetsRoadClass` it is expected
        // that any `.unknown` congestion level for such `MapboxStreetsRoadClass` will be overwritten to `.low` congestion level.
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        expectedCongestionLevels[1] = .unknown
        congestions = route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: [])
        
        // In case if `roadClassesWithOverriddenCongestionLevels` is empty `.unknown` congestion level will not be
        // overwritten.
        congestions.enumerated().forEach {
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
        
        // Make sure that number of `MapboxStreetsRoadClass` is equal to number of congestion levels.
        route.legs.forEach {
            let streetsRoadClasses = $0.streetsRoadClasses
            let segmentCongestionLevels = $0.segmentCongestionLevels
            
            XCTAssertEqual(streetsRoadClasses.count, segmentCongestionLevels?.count)
        }
    }
    
    func testRouteStreetsRoadClassesNotPresent() {
        let route = loadRoute(from: "route-with-not-present-road-classes")
        var congestions = route.congestionFeatures()
        let expectedCongestionLevels: [CongestionLevel] = [
            .unknown,
            .low,
            .moderate,
            .unknown,
            .low
        ]
        
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        congestions = route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: [.motorway, .secondary, .ferry])
        
        // Since `SreetsRoadClass`es are not present in this route congestion levels should remain unchanged after
        // modifying `roadClassesWithOverriddenCongestionLevels`, `streetsRoadClasses` should be empty as well.
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        route.legs.forEach {
            let streetsRoadClasses = $0.streetsRoadClasses

            XCTAssertEqual(streetsRoadClasses.count, 0)
        }
    }
    
    func testRouteStreetsRoadClassesDifferentAndSameCongestion() {
        let route = loadRoute(from: "route-with-same-congestion-different-road-classes")
        var congestions = route.congestionFeatures()
        var expectedCongestionLevels: [CongestionLevel] = [
            .unknown
        ]
        
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        // It is expected that congestion will be overridden only for `RoadClasses` added in `roadClassesWithOverriddenCongestionLevels`.
        // Other congestions should remain unchanged.
        expectedCongestionLevels = [
            .low,
            .unknown
        ]
        congestions = route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: [.street])
        
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        congestions = route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: [.street, .ferry])
        
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
        
        // Since there is only one type of congestion and three `RoadClasses` after overriding all of them
        // all congestion levels should we changed from `.unknown` to `.low`.
        expectedCongestionLevels = [
            .low
        ]
        congestions = route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: [.street, .ferry, .motorway])
        
        congestions.enumerated().forEach {
            XCTAssertEqual(congestionLevel($0.element), expectedCongestionLevels[$0.offset])
        }
    }
    
    func testRoadClassesWithOverriddenCongestionLevelsRemovesDuplicates() {
        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        navigationMapView.roadClassesWithOverriddenCongestionLevels = [.aerialway, .construction, .construction, .golf]
        
        XCTAssertEqual(navigationMapView.roadClassesWithOverriddenCongestionLevels?.count, 3)
    }

    // Disabled. TODO: Find out why buildings aren't highlighted
    func disabled_testHighlightBuildings() {
        let featureQueryExpectation = XCTestExpectation(description: "Wait for building to be highlighted.")

        let navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 37.79060960181454, longitude: -122.39564506250244),
                                          zoom: 17.0,
                                          bearing: 0.0,
                                          pitch: 0.0)
        navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
        let buildingHighlightCoordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.79066471218174, longitude: -122.39581404166825),
            CLLocationCoordinate2D(latitude: 37.78999490647732, longitude: -122.39485917526815)
        ]
        navigationMapView.highlightBuildings(at: buildingHighlightCoordinates, in3D: true, completion: { (result) -> Void in
            if result == true  {
                featureQueryExpectation.fulfill()
            } else {
                XCTFail("Building highlighted failed.")
            }
        })
        
        wait(for: [featureQueryExpectation], timeout: 5.0)
    }
    
    func testFinalDestinationAnnotationIsPresent() {
        
        class NavigationMapViewDelegateMock: NavigationMapViewDelegate {
            
            var didAddFinalDestinationAnnotation = false
            
            func navigationMapView(_ navigationMapView: NavigationMapView,
                                   didAdd finalDestinationAnnotation: PointAnnotation,
                                   pointAnnotationManager: PointAnnotationManager) {
                didAddFinalDestinationAnnotation = true
            }
        }
        
        let navigationMapView = NavigationMapView(frame: UIScreen.main.bounds)
        
        let navigationMapViewDelegateMock = NavigationMapViewDelegateMock()
        navigationMapView.delegate = navigationMapViewDelegateMock
        
        navigationMapView.showWaypoints(on: route)
        
        // Right after calling `NavigationMapView.showWaypoints(on:legIndex:)` and before loading actual
        // `MapView` style it is expected that `NavigationMapView.finalDestinationAnnotation` is assigned
        // to non-nil value.
        XCTAssertNotNil(navigationMapView.finalDestinationAnnotation, "Final destination annotation should not be nil.")
        XCTAssertNil(navigationMapView.pointAnnotationManager, "Point annotation manager should be nil.")
        
        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330
            ],
            "zoom": 15,
            "sources": [],
            "layers": []
        ]
        
        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")
        
        let didAddFinalDestinationAnnotationExpectation = self.expectation {
            return navigationMapViewDelegateMock.didAddFinalDestinationAnnotation
        }
        
        navigationMapView.mapView.mapboxMap.loadStyleJSON(styleJSON)
        
        wait(for: [didAddFinalDestinationAnnotationExpectation], timeout: 5.0)
        
        // After fully loading style `NavigationMapView.finalDestinationAnnotation` should be assigned to nil and
        // `NavigationMapView.pointAnnotationManager` must become valid.
        XCTAssertNil(navigationMapView.finalDestinationAnnotation, "Final destination annotation should be nil.")
        XCTAssertNotNil(navigationMapView.pointAnnotationManager, "Point annotation manager should not be nil.")
        XCTAssertEqual(navigationMapView.pointAnnotationManager?.annotations.count,
                       1,
                       "Only final destination annotation should be present.")
        XCTAssertEqual(navigationMapView.pointAnnotationManager?.annotations.first?.id,
                       NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation,
                       "Point annotation identifiers should be equal.")
    }
}
