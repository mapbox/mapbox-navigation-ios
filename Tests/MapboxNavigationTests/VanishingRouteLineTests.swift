import XCTest
import MapboxDirections
import TestHelper
import MapboxMaps
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class VanishingRouteLineTests: TestCase {
    let errorAllowed = 1e-6
    var navigationMapView: NavigationMapView!
    var window = UIWindow()
    
    override func setUp() {
        super.setUp()
        navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
        window.addSubview(navigationMapView)
    }
    
    override func tearDown() {
        navigationMapView.removeFromSuperview()
        navigationMapView = nil
        super.tearDown()
    }
    
    func getRoute() -> Route {
        let routeData = Fixture.JSONFromFileNamed(name: "short_route")
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        var testRoute: Route?
        XCTAssertNoThrow(testRoute = try decoder.decode(Route.self, from: routeData))
        guard let route = testRoute else {
            preconditionFailure("Route is invalid.")
        }
        
        return route
    }
    
    func getMultilegRoute() -> Route {
        let routeData = Fixture.JSONFromFileNamed(name: "multileg_route")
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2DMake(-77.1576396, 38.7830304),
            CLLocationCoordinate2DMake(-77.1670888, 38.7756155),
            CLLocationCoordinate2DMake(-77.1534183, 38.7708948),
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
    
    func getStraightLineRoute() -> Route {
        let routeData = Fixture.JSONFromFileNamed(name: "route-with-straight-line")
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2DMake(55.026291, 37.975393),
            CLLocationCoordinate2DMake(55.026720, 30.798226)
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
    
    func getRouteProgress(_ route: Route? = nil) -> RouteProgress {
        let route = route ?? getRoute()
        let routeProgress = RouteProgress(route: route, options: routeOptions, legIndex: 0, spokenInstructionIndex: 0)
        routeProgress.currentLegProgress = RouteLegProgress(leg: route.legs[0], stepIndex: 2, spokenInstructionIndex: 0)
        routeProgress.currentLegProgress.currentStepProgress = RouteStepProgress(step: route.legs[0].steps[2], spokenInstructionIndex: 0)
        return routeProgress
    }
    
    func getEmptyRoute() -> Route {
        let route = getRoute()
        let routeLeg = route.legs.first!
        let emptySteps = routeLeg.steps.map { (routeStep: RouteStep) -> RouteStep in
            routeStep.shape?.coordinates = []
            return routeStep
        }
        let emptyLeg = RouteLeg(steps: emptySteps,
                                name: routeLeg.name,
                                distance: routeLeg.distance,
                                expectedTravelTime: routeLeg.expectedTravelTime,
                                profileIdentifier: routeLeg.profileIdentifier)
        let emptyRoute = Route(legs: [emptyLeg], shape: route.shape, distance: route.distance, expectedTravelTime: route.expectedTravelTime)
        return emptyRoute
    }
    
    func getUnstartedRouteProgress(route: Route) -> RouteProgress {
        let routeProgress = RouteProgress(route: route, options: routeOptions, legIndex: 0, spokenInstructionIndex: 0)
        routeProgress.currentLegProgress = RouteLegProgress(leg: route.legs[0], stepIndex: 0, spokenInstructionIndex: 0)
        routeProgress.currentLegProgress.currentStepProgress = RouteStepProgress(step: route.legs[0].steps[0], spokenInstructionIndex: 0)
        routeProgress.currentLegProgress.currentStepProgress.distanceTraveled = 0.0
        return routeProgress
    }
    
    func updateVanishingRouteLine(route: Route, routeProgress: RouteProgress, coordinate: CLLocationCoordinate2D) {
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route])
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        navigationMapView.updateFractionTraveled(coordinate: coordinate)
    }
    
    func lineGradientToString(lineGradient: Value<StyleColor>?) -> String {
        guard let halfStringFromLineGradient = lineGradient.debugDescription.components(separatedBy: "(").last,
              let stringFromLineGradient = halfStringFromLineGradient.components(separatedBy: ")").first else {
            preconditionFailure("Line gradient string is invalid.")
        }
        return stringFromLineGradient
    }
    
    func setUpCameraZoom(at zoomeLevel: CGFloat) {
        let cameraState = navigationMapView.mapView.cameraState
        let cameraOptions = CameraOptions(center: cameraState.center,
                                          padding: cameraState.padding,
                                          zoom: zoomeLevel,
                                          bearing: cameraState.bearing,
                                          pitch: cameraState.pitch)
        navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
        XCTAssertEqual(navigationMapView.mapView.cameraState.zoom, zoomeLevel, "Zoom levels should be equal.")
    }
    
    func testInitPrimaryRoutePoints() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/internal/route/line/MapboxRouteLineUtilsTest.kt#L1798
        var route = getMultilegRoute()
        var routePoints = navigationMapView.parseRoutePoints(route: route)
        
        // Because mapbox-directions-swift parses the route with one more duplicate coordinate in the last step of each route leg.
        // The two leg route has two more coordinates compared with Android.
        XCTAssertEqual(routePoints.flatList.count, 130)
        XCTAssertEqual(routePoints.nestedList.flatMap{$0}.count, 15)
        XCTAssertEqual(routePoints.flatList[1].latitude, routePoints.flatList[2].latitude)
        XCTAssertEqual(routePoints.flatList[1].longitude, routePoints.flatList[2].longitude)
        XCTAssertEqual(routePoints.flatList[128].latitude, routePoints.flatList[129].latitude, accuracy: errorAllowed)
        XCTAssertEqual(routePoints.flatList[128].longitude, routePoints.flatList[129].longitude, accuracy: errorAllowed)
        
        route = getStraightLineRoute()
        routePoints = navigationMapView.parseRoutePoints(route: route)
        XCTAssertEqual(routePoints.flatList.count, 6)
        // This route has 3 steps.
        XCTAssertEqual(routePoints.nestedList.flatMap{$0}.count, 3)
        
        guard let routeLineGranularDistances = navigationMapView.calculateGranularDistances(routePoints.flatList) else {
            XCTFail("Failed to calculate granular distances.")
            return
        }
        let distanceArray = routeLineGranularDistances.distanceArray
        XCTAssertEqual(distanceArray.count, routePoints.flatList.count)
        XCTAssertEqual(distanceArray.first?.distanceRemaining, routeLineGranularDistances.distance)
        XCTAssertEqual(distanceArray.first?.point, routePoints.flatList.first)
        XCTAssertEqual(distanceArray.last?.distanceRemaining, 0.0)
        XCTAssertEqual(distanceArray.last?.point, routePoints.flatList.last)
    }
    
    func testUpdateUpcomingRoutePointIndex() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/route/line/api/MapboxRouteLineApiTest.kt#L802
        let route = getRoute()
        let routeProgress = getRouteProgress()
        
        navigationMapView.initPrimaryRoutePoints(route: route)
        guard let flatList = navigationMapView.routePoints?.flatList,
              let nestedPoints = navigationMapView.routePoints?.nestedList,
              let currentLegPoints = nestedPoints.first else {
            XCTFail("Failed to initialize primary route points.")
            return
        }
        // This route has 9 coordinates.
        XCTAssertEqual(flatList.count, 9)
        // This route has 1 leg.
        XCTAssertEqual(nestedPoints.count, 1)
        // This route leg has 4 steps.
        XCTAssertEqual(currentLegPoints.count, 4)
        XCTAssertEqual(currentLegPoints[safe: 2]?.count, routeProgress.currentLegProgress.currentStep.shape?.coordinates.count)
        
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0.0)
        
        var traveledPoints = 0
        traveledPoints += currentLegPoints[0].count
        traveledPoints += currentLegPoints[1].count
        // Because user has arrived at the first coordinate of current step with distanceTraveled on this step as 0.0.
        traveledPoints += 1
        
        var remainingPoints = 0
        remainingPoints += currentLegPoints[3].count
        // Because user has arrived at the first coordinate with other coordinates remaining in current step.
        remainingPoints += currentLegPoints[2].count - 1
        
        let expectedRemainingPoints = flatList.count - traveledPoints
        XCTAssertEqual(remainingPoints, expectedRemainingPoints)
        XCTAssertEqual(expectedRemainingPoints, 3)
        
        let expectedUpcomingPointIndex = traveledPoints
        XCTAssertEqual(navigationMapView.routeRemainingDistancesIndex, expectedUpcomingPointIndex)
    }
    
    func testUpdateUpcomingRoutePointIndexWhenPrimaryRoutePointsIsNill() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/route/line/api/MapboxRouteLineApiTest.kt#L846
        let routeProgress = getRouteProgress()
        
        // When the route points not initialized yet, the upcoming route point index is expected to be `nil`.
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        XCTAssertNil(navigationMapView.routeRemainingDistancesIndex)
    }
    
    func testUpdateFractionTraveled() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/route/line/api/MapboxRouteLineApiTest.kt#L636
        var routeProgress = getRouteProgress()
        var route = routeProgress.route
        var coordinate = route.shape!.coordinates[1]
        updateVanishingRouteLine(route: route, routeProgress: routeProgress, coordinate: coordinate)
        
        // When `routeLineTracksTraversal` enabled, the `fractionTraveled` is expected to be updated after
        // the upcoming route point index update and a location update.
        var expectedFractionTraveled = 0.3240769449298392
        XCTAssertEqual(navigationMapView.fractionTraveled, expectedFractionTraveled, accuracy: errorAllowed)
        
        route = getStraightLineRoute()
        routeProgress = RouteProgress(route: route, options: routeOptions, legIndex: 0, spokenInstructionIndex: 0)
        routeProgress.currentLegProgress = RouteLegProgress(leg: route.legs[0], stepIndex: 0, spokenInstructionIndex: 0)
        routeProgress.currentLegProgress.currentStepProgress = RouteStepProgress(step: route.legs[0].steps[0], spokenInstructionIndex: 0)
        routeProgress.currentLegProgress.currentStepProgress.distanceTraveled = 43
        
        coordinate = CLLocationCoordinate2D(latitude: 55.02625104819779, longitude: 30.798893352940773)
        updateVanishingRouteLine(route: route, routeProgress: routeProgress, coordinate: coordinate)
        
        let expectedUpcomingPointIndex = 1
        XCTAssertEqual(navigationMapView.routeRemainingDistancesIndex, expectedUpcomingPointIndex, "User just passed the first coordinate of the first step.")
        
        guard let firstCoordinate = route.shape?.coordinates.first,
              let totalDistance = route.shape?.distance() else {
            XCTFail("Failed to update vanishing route line.")
            return
        }
        
        let traveledDistance = firstCoordinate.distance(to: coordinate)
        expectedFractionTraveled = traveledDistance / totalDistance
        // Compare the Haversine calculated result with the project distance calculated result.
        XCTAssertEqual(navigationMapView.fractionTraveled, expectedFractionTraveled, accuracy: errorAllowed)
    }
    
    func testEmptyRouteWithValidRouteProgress() {
        let route = getEmptyRoute()
        let routeProgress = getRouteProgress(route)
        
        let coordinate = CLLocationCoordinate2DMake(-122.5237429, 37.975393)
        updateVanishingRouteLine(route: route, routeProgress: routeProgress, coordinate: coordinate)
        
        // Route without coordinates inside its steps would lead to 0 routeRemainingDistancesIndex.
        XCTAssertEqual(navigationMapView.routeRemainingDistancesIndex, 0)
        XCTAssertEqual(navigationMapView.fractionTraveled, 0.0, accuracy: 0)
    }
    
    func testUnstartedRouteProgressWithValidRoute() {
        let route = getRoute()
        let routeProgress = getUnstartedRouteProgress(route: route)
        
        let coordinate = CLLocationCoordinate2DMake(-122.5237429, 37.975393)
        updateVanishingRouteLine(route: route, routeProgress: routeProgress, coordinate: coordinate)
        
        XCTAssert(navigationMapView.routeRemainingDistancesIndex! >= 0, "Non-empty route should have valid routeRemainingDistancesIndex.")
        XCTAssertEqual(navigationMapView.fractionTraveled, 0.0, accuracy: 0)
    }
    
    func testUpdateRouteLineWithDifferentDistance() {
        let routeProgress = getRouteProgress()
        let route = routeProgress.route
        let coordinate = route.shape!.coordinates[1]
        
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)

        // By setting the zoom level of camera in `navigationMapView` to 5, the meters per pixel at latitude at high zoom level would be really large.
        // When a location update comes in with a small distance change, it's expected to be less than the meters per pixel,
        // In this case, the `fractionTraveled` and the vanishing route line won't be updated.
        setUpCameraZoom(at: 5.0)
        navigationMapView.travelAlongRouteLine(to: coordinate)
        XCTAssertTrue(navigationMapView.fractionTraveled == 0.0, "Failed to avoid updating route line when the distance is smaller than 1 pixel.")
        
        // By setting the zoom level of camera in `navigationMapView` to 16, the meters per pixel at latitude at low zoom level would be really small.
        // When a location update comes in with a distance change larger than or equal to the meters per pixel,
        // the `fractionTraveled` and vanishing route line will both be updated.
        setUpCameraZoom(at: 17.0)
        navigationMapView.travelAlongRouteLine(to: coordinate)
        XCTAssertTrue(navigationMapView.fractionTraveled != 0.0, "Failed to update route line when the distance is larger than or equal to 1 pixel.")
    }
    
    func testSwitchRouteLineTracksTraversalDuringNavigation() {
        let routeProgress = getRouteProgress()
        let route = routeProgress.route
        let coordinate = route.shape!.coordinates[1]
        
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        setUpCameraZoom(at: 16.0)
        
        navigationMapView.travelAlongRouteLine(to: coordinate)
        let expectedFractionTraveled = 0.3240769449298392
        let actualFractionTraveled = navigationMapView.fractionTraveled
        XCTAssertEqual(actualFractionTraveled, expectedFractionTraveled, accuracy: errorAllowed, "Failed to update route line when routeLineTracksTraversal enabled.")
        
        let layerIdentifier = route.identifier(.route(isMainRoute: true))
        do {
            // During the active navigation, when disabling `routeLineTracksTraversal`, the new route line will be generated,
            // and the `fractionTraveled` will be 0.0.
            navigationMapView.routeLineTracksTraversal = false
            guard let nonTrackingRouteLineLayer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer else {
                XCTFail("Route line layer should be added.")
                return
            }
            var gradientExpression = nonTrackingRouteLineLayer.lineGradient.debugDescription
            XCTAssertEqual(navigationMapView.fractionTraveled, 0.0)
            XCTAssert(!gradientExpression.contains(actualFractionTraveled.description), "Failed to stop vanishing effect when routeLineTracksTraversal disabled.")
            
            // During the active navigation, when enabling `routeLineTracksTraversal`, the new line gradient stops of current route will be generated.
            // The `fractionTraveled` and the route line are expected to be updated after a new `routeProgress` and location update comes in
            navigationMapView.routeLineTracksTraversal = true
            navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
            navigationMapView.travelAlongRouteLine(to: coordinate)
            guard let trackingRouteLineLayer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer else {
                XCTFail("Route line layer should be added.")
                return
            }
            gradientExpression = trackingRouteLineLayer.lineGradient.debugDescription
            XCTAssert(gradientExpression.contains(actualFractionTraveled.description), "Failed to restore vanishing effect when routeLineTracksTraversal enabled.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testRouteLineGradientWithCombinedColor() {
        let route = getRoute()
        
        // When different congestion levels have same color, the line gradient stops are expected to combine these congestion level.
        navigationMapView.trafficModerateColor = navigationMapView.trafficUnknownColor
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        
        let expectedGradientStops = [0.0 : navigationMapView.trafficUnknownColor]
        XCTAssertEqual(expectedGradientStops, navigationMapView.currentLineGradientStops, "Failed to combine the same color of congestion segment.")
    }
    
    func testSwitchCrossfadesCongestionSegments() {
        let routeProgress = getRouteProgress()
        let route = routeProgress.route
        let coordinate = route.shape!.coordinates[1]

        navigationMapView.trafficUnknownColor = UIColor.blue
        navigationMapView.trafficModerateColor = UIColor.red
        navigationMapView.traversedRouteColor = UIColor.clear
        setUpCameraZoom(at: 16.0)
        
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        navigationMapView.travelAlongRouteLine(to: coordinate)

        let fractionTraveled = navigationMapView.fractionTraveled
        let fractionTraveledNextDown = Double(CGFloat(fractionTraveled).nextDown)
        
        var expectedExpressionString = "[step, [line-progress], [rgba, 0.0, 0.0, 255.0, 1.0], 0.0, [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTraveledNextDown), [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTraveled), [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625797, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625799, [rgba, 255.0, 0.0, 0.0, 1.0]]"

        let layerIdentifier = route.identifier(.route(isMainRoute: true))
        do {
            guard let steppedRouteLineLayer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer else {
                XCTFail("Route line layer should be added.")
                return
            }
            var lineGradientString = lineGradientToString(lineGradient: steppedRouteLineLayer.lineGradient)
            XCTAssertEqual(lineGradientString, expectedExpressionString, "Failed to apply step color transition between two different congestion level.")

            // During active navigation with `routeLineTracksTraversal` and `crossfadesCongestionSegments` both enabled,
            // the route line should re-generate the gradient stops and update the line gradient expression
            // when there's a location update comes in.
            expectedExpressionString = "[interpolate, [linear], [line-progress], 0.0, [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTraveledNextDown), [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTraveled), [rgba, 0.0, 0.0, 255.0, 1.0], 0.8482948363463217, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9482948363463218, [rgba, 255.0, 0.0, 0.0, 1.0]]"
            navigationMapView.crossfadesCongestionSegments = true
            navigationMapView.travelAlongRouteLine(to: coordinate)
            
            guard let crossfadingRouteLineLayer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer else {
                XCTFail("Route line layer should be added.")
                return
            }
            lineGradientString = lineGradientToString(lineGradient: crossfadingRouteLineLayer.lineGradient)
            XCTAssertEqual(lineGradientString, expectedExpressionString, "Failed to apply soft color transition between two different congestion level.")
            
            // During active navigation with `crossfadesCongestionSegments` enabled but `routeLineTracksTraversal` disabled,
            // the route line should be re-generated directly.
            expectedExpressionString = "[step, [line-progress], [rgba, 0.0, 0.0, 255.0, 1.0], 0.0, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625797, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625799, [rgba, 255.0, 0.0, 0.0, 1.0]]"
            navigationMapView.routeLineTracksTraversal = false
            navigationMapView.crossfadesCongestionSegments = false
            
            guard let trackingRouteLineLayer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer else {
                XCTFail("Route line layer should be added.")
                return
            }
            lineGradientString = lineGradientToString(lineGradient: trackingRouteLineLayer.lineGradient)
            XCTAssertEqual(lineGradientString, expectedExpressionString, "Failed to apply step color transition between two different congestion level and show a whole new route line.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProjectedDistance() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/internal/route/line/MapboxRouteLineUtilsTest.kt#L257
        
        let startCoordinate = CLLocationCoordinate2D(latitude: 37.974092, longitude: -122.525212)
        let endCoordinate = CLLocationCoordinate2D(latitude: 37.974569579999944, longitude: -122.52509389295653)
        
        // It's to test the calculation of project distance using [EPSG:3857 projection](https://epsg.io/3857).
        let distance = startCoordinate.projectedDistance(to: endCoordinate)
        let expectedDistance = 0.0000017145850113848236
        XCTAssertEqual(distance, expectedDistance, "Failed to calculate the right project distance.")
    }
    
    func testRouteLineGradientWithoutCongestionLevel() {
        let route = getRoute()
        route.legs.first!.segmentCongestionLevels = nil
        route.legs.first!.segmentNumericCongestionLevels = nil
        XCTAssertNil(route.legs.first!.resolvedCongestionLevels, "Failed to get nil resolvedCongestionLevels from route.")

        // When there's no congestion information found or parsed from route features,
        // the route line is expcted to apply `trafficUnknownColor` for the main route.
        let congestionFeatures = route.congestionFeatures(legIndex: 0)
        let currentLineGradientStops = navigationMapView.routeLineCongestionGradient(route,
                                                                                     congestionFeatures: congestionFeatures,
                                                                                     fractionTraveled: 0.0)
        XCTAssertEqual(currentLineGradientStops[0.0], navigationMapView.trafficUnknownColor, "Failed to use trafficUnknownColor for route line when no congestion level found.")
    }
    
    func testFindDistanceToNearestPointOnCurrentLine() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0478c43781fdf7489f10f22c0055fadf181970f6/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/internal/route/line/MapboxRouteLineUtilsTest.kt#L814
        
        let route = getMultilegRoute()
        guard let coordinate = route.shape?.coordinates[15] else {
            XCTFail("Coordinate is invalid.")
            return
        }
        let granularDistances = navigationMapView.calculateGranularDistances(route.shape!.coordinates)!
        
        // It's to test the distance calculation from user location to pre-existing route line.
        let expectedResult = 141.6772603078415
        let result = navigationMapView.findDistanceToNearestPointOnCurrentLine(coordinate: coordinate, granularDistances: granularDistances, upcomingIndex: 12)
        XCTAssertEqual(expectedResult, result, accuracy: 0.01, "Failed to calculate the distance from one coordinate to current route line.")
    }
    
    func testUpdateFractionTraveledWhenUserOffRouteLine() {
        let routeProgress = getRouteProgress()
        let route = routeProgress.route
        let coordinate = CLLocationCoordinate2D(latitude: 37.7577627, longitude: -122.4727051)
        
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        setUpCameraZoom(at: 16.0)
        
        // When the distance of user location to pre-existing route line is larger than the `offRouteDistanceCheckEnabled`,
        // the route line is expected to stop updating until a new route line gets generated.
        let expectedFractionTraveled = 0.0
        navigationMapView.updateFractionTraveled(coordinate: coordinate)
        XCTAssertTrue(expectedFractionTraveled == navigationMapView.fractionTraveled, "Failed to stop updating fractionTraveled when user off the route line.")
    }
    
    func testSwitchshowsRestrictedAreasOnRoute() {
        let routeProgress = getRouteProgress()
        let route = routeProgress.route
        let coordinate = route.shape!.coordinates[1]
        
        navigationMapView.trafficUnknownColor = UIColor.blue
        navigationMapView.trafficModerateColor = UIColor.red
        navigationMapView.traversedRouteColor = UIColor.clear
        setUpCameraZoom(at: 16.0)
        
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        navigationMapView.addArrow(route: route, legIndex: 0, stepIndex: 2)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        navigationMapView.travelAlongRouteLine(to: coordinate)

        let fractionTraveled = navigationMapView.fractionTraveled
        let fractionTraveledNextDown = Double(CGFloat(fractionTraveled).nextDown)
        let expectedExpressionString = "[step, [line-progress], [rgba, 0.0, 0.0, 255.0, 1.0], 0.0, [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTraveledNextDown), [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTraveled), [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625797, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625799, [rgba, 255.0, 0.0, 0.0, 1.0]]"

        let layerIdentifier = route.identifier(.route(isMainRoute: true))
        
        var allLayerIds = navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.map({ $0.id })
        guard let indexOfMainRouteLayer = allLayerIds.firstIndex(of: route.identifier(.route(isMainRoute: true))),
              let indexOfArrowStrokeLayer = allLayerIds.firstIndex(of: NavigationMapView.LayerIdentifier.arrowStrokeLayer) else {
                  XCTFail("Failed to find all the layers")
                  return
              }
        XCTAssert(indexOfMainRouteLayer < indexOfArrowStrokeLayer, "Arrow stroke layer should be above main route layer")
        
        // When the `NavigationMapView.showsRestrictedAreasOnRoute` is turned on during active navigation with `routeLineTracksTraversal` enabled,
        // the previous vanishing effect should be kept, and the new restricted areas layer should be added
        // above the main route line layer but below the arrow stroke layer.
        navigationMapView.showsRestrictedAreasOnRoute = true
        do {
            guard let layer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer else {
                XCTFail("Route line layer should be added.")
                return
            }
            let lineGradientString = lineGradientToString(lineGradient: layer.lineGradient)
            XCTAssertEqual(lineGradientString, expectedExpressionString, "Failed to keep the vanishing effect when showsRestrictedAreasOnRoute turns on.")
            
            allLayerIds = navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.map({ $0.id })
            guard let indexOfMainRouteLayer = allLayerIds.firstIndex(of: route.identifier(.route(isMainRoute: true))),
                  let indexOfRestrictedAreas = allLayerIds.firstIndex(of: route.identifier(.restrictedRouteAreaRoute)),
                  let indexOfArrowStrokeLayer = allLayerIds.firstIndex(of: NavigationMapView.LayerIdentifier.arrowStrokeLayer) else {
                      XCTFail("Failed to find all the layers")
                      return
                  }
            XCTAssert(indexOfMainRouteLayer < indexOfRestrictedAreas, "Restricted areas route layer should be above main route layer.")
            XCTAssert(indexOfRestrictedAreas < indexOfArrowStrokeLayer, "Restricted areas route layer should be below arrow stroke layer.")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        // When the `NavigationMapView.showsRestrictedAreasOnRoute` is turned off during active navigation with `routeLineTracksTraversal` enabled,
        // the previous vanishing effect should be kept, but the restricted areas layer and its source should be removed.
        navigationMapView.showsRestrictedAreasOnRoute = false
        do {
            guard let layer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer else {
                XCTFail("Route line layer should be added.")
                return
            }
            let lineGradientString = lineGradientToString(lineGradient: layer.lineGradient)
            XCTAssertEqual(lineGradientString, expectedExpressionString, "Failed to keep the vanishing effect when showsRestrictedAreasOnRoute turns off.")
            XCTAssertFalse(navigationMapView.mapView.mapboxMap.style.layerExists(withId: route.identifier(.restrictedRouteAreaRoute)), "Failed to remove restricted areas route layer.")
            XCTAssertFalse(navigationMapView.mapView.mapboxMap.style.sourceExists(withId: route.identifier(.restrictedRouteAreaSource)), "Failed to remove restricted areas route source.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
